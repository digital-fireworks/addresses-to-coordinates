#!/usr/bin/env swift

import Foundation

struct GeocodeResult {
    let latitude: Double
    let longitude: Double
}

class AddressGeocoder {
    func geocodeAddress(_ address: String, dispatchGroup: DispatchGroup, completion: @escaping (GeocodeResult?) -> Void) {
        // Use Nominatim (OpenStreetMap) API for free geocoding
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://nominatim.openstreetmap.org/search?format=json&q=\(encodedAddress)&limit=1"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL for address: \(address)")
            completion(nil)
            return
        }
        
        dispatchGroup.enter()
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                print("Network error for '\(address)': \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received for address: \(address)")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let first = json.first,
                   let latString = first["lat"] as? String,
                   let lonString = first["lon"] as? String,
                   let lat = Double(latString),
                   let lon = Double(lonString) {
                    completion(GeocodeResult(latitude: lat, longitude: lon))
                } else {
                    print("No location found for address: \(address)")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error for '\(address)': \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func processCSV(inputPath: String, outputPath: String) {
        guard let inputData = FileManager.default.contents(atPath: inputPath),
              let inputString = String(data: inputData, encoding: .utf8) else {
            print("Error: Could not read input file at \(inputPath)")
            exit(1)
        }
        
        let lines = inputString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            print("Error: Input file is empty")
            exit(1)
        }
        
        var outputLines = ["ID,Address,Latitude,Longitude"]
        let dispatchGroup = DispatchGroup()
        let queue = DispatchQueue(label: "geocoding", qos: .userInitiated, attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: 5) // Limit concurrent requests
        let outputQueue = DispatchQueue(label: "output", qos: .userInitiated)
        
        var results: [Int: String] = [:]
        var validIndices: [Int] = []
        
        for (index, line) in lines.enumerated() {
            let components = line.components(separatedBy: ",")
            guard components.count >= 2 else {
                print("Warning: Skipping malformed line \(index + 1): \(line)")
                continue
            }
            
            let idString = components[0].trimmingCharacters(in: .whitespaces)
            guard let id = Int(idString) else {
                print("Warning: Invalid ID on line \(index + 1): \(idString)")
                continue
            }
            
            let address = components.dropFirst().joined(separator: ",").trimmingCharacters(in: .whitespaces)
            
            validIndices.append(index)
            
            dispatchGroup.enter()
            queue.async {
                semaphore.wait()
                defer { 
                    semaphore.signal()
                    dispatchGroup.leave()
                }
                
                print("Geocoding \(index + 1)/\(lines.count): \(address)")
                
                self.geocodeAddress(address, dispatchGroup: dispatchGroup) { coordinate in
                    let resultLine: String
                    if let coordinate = coordinate {
                        resultLine = "\(id),\"\(address)\",\(coordinate.latitude),\(coordinate.longitude)"
                        print("✓ \(resultLine)")
                    } else {
                        resultLine = "\(id),\"\(address)\",,"
                        print("✗ \(resultLine)")
                    }
                    
                    outputQueue.sync {
                        results[index] = resultLine
                    }
                }
            }
        }
        
        dispatchGroup.wait()
        
        // Sort results by original order and append to output
        for index in validIndices.sorted() {
            if let resultLine = results[index] {
                outputLines.append(resultLine)
            }
        }
        
        let outputString = outputLines.joined(separator: "\n")
        
        do {
            try outputString.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("Successfully geocoded \(validIndices.count) addresses")
            print("Output written to: \(outputPath)")
        } catch {
            print("Error writing output file: \(error)")
            exit(1)
        }
    }
}

func main() {
    let arguments = CommandLine.arguments
    
    guard arguments.count == 3 else {
        print("Usage: \(arguments[0]) <input_csv> <output_csv>")
        print("Input CSV format: ID,Address")
        print("Output CSV format: ID,Address,Latitude,Longitude")
        exit(1)
    }
    
    let inputPath = arguments[1]
    let outputPath = arguments[2]
    
    let geocoder = AddressGeocoder()
    geocoder.processCSV(inputPath: inputPath, outputPath: outputPath)
}

main()
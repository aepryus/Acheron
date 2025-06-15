//
//  CSV.swift
//  Acheron
//
//  Created by Joe Charlier on 6/14/25.
//

public class CSV {
    public static func split(csv: String) -> [String] { csv.components(separatedBy: .newlines).filter { !$0.isEmpty } }
    public static func split(line: String) -> [String] {
        var results: [String] = []
        
        var inside: Bool = false
        var sb: String = ""
        var i: Int = 0
        
        while i < line.count {
            if inside && line[i] == "\"" && i+1 < line.count && line[i+1] == "\"" {
                i += 1
                sb.append("\"")
            }
            else if !inside && line[i] == "," {
                    results.append(sb)
                    sb = ""
            }
            else if line[i] == "\"" { inside = !inside }
            else { sb.append(line[i]) }
            i += 1
        }
        
        if !sb.isEmpty { results.append(sb) }
        
        return results
    }
}

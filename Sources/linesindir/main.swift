import Foundation
import ArgumentParser
import TSCBasic
import TSCUtility

enum DirectoryError: Error {
    case noFilesFound
}

struct LinesInDirectory: ParsableCommand {
    @Option(name: [.customShort("d"), .customLong("directory", withSingleDash: false)], help: "URL of directory that you want to get the count of lines") var directory: String = FileManager().currentDirectoryPath
    @Argument(help: "Extension of files to check") var fileExtensions: [String] = ["swift"]
    @Flag(name: [.customShort("a"), .customLong("all", withSingleDash: false)], help: "Check all") var all: Bool = false
    
    func getAllFiles(at url: Foundation.URL, ext: [String]) -> [Foundation.URL] {
        var files =  [Foundation.URL]()
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: []) {
            for case let fileURL as Foundation.URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    do {
                        let _ = try String(contentsOf: fileURL)
                    } catch {
                        continue
                    }
                    if fileAttributes.isRegularFile! {
                        if all || ext.contains(fileURL.pathExtension) {
                            files.append(fileURL)
                        }
                    }
                } catch { print(error, fileURL) }
            }
        }
        
        return files
    }
    
    func run() throws {
        let terminalController = TerminalController(stream: stdoutStream)
        
        let fileManager = FileManager()
        
        let currentDir = fileManager.currentDirectoryPath
        var url = URL(string: currentDir)!
        
        url.appendPathComponent(directory, isDirectory: true)
        
        
        var lines = 0
        terminalController?.write("Collecting files...", inColor: .white, bold: false)
        
        let files: [Foundation.URL] = getAllFiles(at: url, ext: fileExtensions)
        
        if files.count == 0 {
            
            throw DirectoryError.noFilesFound
        }
        
        terminalController?.clearLine()
        let animation = PercentProgressAnimation(stream: stdoutStream, header: "Counting files...")
        try files.enumerated().forEach { index, fileURL in
            let stringFile = try String(contentsOf: fileURL)
            let linesInFile = stringFile.components(separatedBy: .newlines).count
            lines += linesInFile
            
            animation.update(step: index + 1, total: files.count, text: "Lines in file: \(fileURL.lastPathComponent): \(linesInFile)")
        }
        animation.complete(success: true)
        animation.clear()
        terminalController?.endLine()
        let filesToLook = all ? "all" : fileExtensions.joined(separator: ", ")
        terminalController?.write("Looking at \(filesToLook) files: ", inColor: .yellow, bold: true)
        terminalController?.endLine()
        terminalController?.endLine()
        
        let totalFiles = terminalController?.wrap(String(files.count), inColor: .red, bold: true)
        terminalController?.write("Total number of files: \(totalFiles!)", inColor: .green)
        terminalController?.endLine()
        
        let totalLines = terminalController?.wrap(String(lines), inColor: .red, bold: true)
        terminalController?.write("Total number of lines: \(totalLines!)", inColor: .green)
        terminalController?.endLine()
    }
}

LinesInDirectory.main()

//
//  APChangesManager.swift
//  APReader
//
//  Created by Tango on 2020/9/4.
//  Copyright © 2020 Tangorios. All rights reserved.
//

import UIKit
import PDFKit

protocol Command {
    func execute()
    func unexecute()
}

class APChangesManager: NSObject {

    var undoEnable: Bool {
        return undoCommands.count > 0
    }
    var redoEnable: Bool {
        return redoCommands.count > 0
    }
    private var undoCommands = [Command]()
    private var redoCommands = [Command]()

    func redo(withCompletionHandler handler: () -> Void) {
        guard !redoCommands.isEmpty, let command = redoCommands.popLast() else {
            return
        }

        command.execute()
        undoCommands.append(command)
        handler()
    }

    func undo(withCompletionHandler handler: () -> Void) {
        guard !undoCommands.isEmpty, let command = undoCommands.popLast() else {
            return
        }

        command.unexecute()
        redoCommands.append(command)
        handler()
    }

    func addInkPDFAnnotation(withPaths path: UIBezierPath?, _ annotation: PDFAnnotation, forPage page: PDFPage) {
        let change = APInkAnnotation(annotation, path: path, forPDFPage: page)
        undoCommands.append(change)
    }

    func addTextAnnotation(_ annotation: [PDFAnnotation], forPage page: PDFPage) {
        let change = APTextAnnotation(annotation, forPage: page)
        undoCommands.append(change)
    }
    
    func addWidgetAnnotation(_ annotation: PDFAnnotation, forPage page: PDFPage) {
        let change = APWidgetAnnotation(annotation, forPage: page)
        undoCommands.append(change)
    }

    func reset() {
        undoCommands.reversed().forEach({ $0.unexecute() })
        clear()
    }

    func clear() {
        undoCommands.removeAll()
        redoCommands.removeAll()
    }
}


//
//  TaskListBundle.swift
//  TaskList
//
//  Created by Xiao Xiao on 2025/10/20.
//

import WidgetKit
import SwiftUI

@main
struct TaskListBundle: WidgetBundle {
    var body: some Widget {
        TaskList()
        TaskListControl()
    }
}

//
//  LavoraMiWidgetLiveActivity.swift
//  LavoraMiWidget
//
//  Created by Andrea Filice on 17/01/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LavoraMiWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LavoraMiWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LavoraMiWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LavoraMiWidgetAttributes {
    fileprivate static var preview: LavoraMiWidgetAttributes {
        LavoraMiWidgetAttributes(name: "World")
    }
}

extension LavoraMiWidgetAttributes.ContentState {
    fileprivate static var smiley: LavoraMiWidgetAttributes.ContentState {
        LavoraMiWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LavoraMiWidgetAttributes.ContentState {
         LavoraMiWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .dynamicIsland(.expanded), using: LavoraMiWidgetAttributes.preview) {
   LavoraMiWidgetLiveActivity()
} contentStates: {
    LavoraMiWidgetAttributes.ContentState.smiley
    LavoraMiWidgetAttributes.ContentState.starEyes
}

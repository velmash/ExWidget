//
//  WGTestWidget.swift
//  WGTestWidget
//
//  Created by 윤형찬 on 4/15/24.
//

import WidgetKit
import SwiftUI

struct TextModel: Codable {
    enum CodingKeys: String, CodingKey {
        case datas = "data"
    }
    
    let datas: [String]
}

struct Provider: AppIntentTimelineProvider {
    //데이터를 불러오기 전(snapshot)에 보여줄 placeholder
    func placeholder(in context: Context) -> SimpleEntry {
//        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
        SimpleEntry(date: Date(), texts: ["Empty"])
    }
    
    //위젯 갤러리에서 위젯을 고를 때 보이는 샘플 데이터를 보여줄때 해당 메소드 호출
    //API를 통해서 데이터를 fetch하여 보여줄때 딜레이가 있는 경우 여기서 샘플 데이터를 하드코딩해서 보여주는 작업도 가능
    // context.isPreview가 true인경우 위젯 갤러리에 위젯이 표출되는 상태
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        do {
            let texts = try await getTexts()
            return SimpleEntry(date: Date(), texts: texts)
        } catch {
            print("Error fetching texts: \(error)")
            return SimpleEntry(date: Date(), texts: [])
        }
    }
    
    // 홈화면에 있는 위젯을 언제 업데이트 시킬것인지 구현하는 부분
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        
        let currentDate = Date()
        do {
            let texts = try await getTexts()
            let entry = SimpleEntry(date: currentDate, texts: texts)
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 3, to: currentDate)!
            return Timeline(entries: [entry], policy: .after(nextRefresh))
        } catch {
            return Timeline(entries: [], policy: .never)
        }
        //.atEnd: 마지막 date가 끝난 후 타임라인 reloading
        //.atAfter: 다음 date가 지난 후 타임라인 reloading
        //.never: 즉시 타임라인 reloading
    }
    
    private func getTexts() async throws -> [String] {
        guard let url = URL(string: "https://meowfacts.herokuapp.com/?count=1") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let textModel = try JSONDecoder().decode(TextModel.self, from: data)
        return textModel.datas
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
//    let configuration: ConfigurationAppIntent
    let texts: [String]
}

struct WGTestWidgetEntryView : View {
    var entry: Provider.Entry
    
    private var randomColor: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
    
    var body: some View {
        ZStack {
            randomColor.opacity(0.7)
            ForEach(entry.texts, id: \.hashValue) { text in
                LazyVStack {
                    Text(text)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .widgetURL(URL(string: getPercentEcododedString("widget://deeplink?text=\(text)")))
                    Divider()
                }
            }
        }
    }
    
    private func getPercentEcododedString(_ string: String) -> String {
      string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    }
}

struct WGTestWidget: Widget {
    let kind: String = "MyWidget"
    
    //Body 안에 사용하는 Configuration
        //AppIntentConfiguration: 사용자가 위젯에서 Edit을 통해 보여지는 내용 변경 가능

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, // 위젯 ID
                               intent: ConfigurationAppIntent.self, // 사용자 설정 컨피그
                               provider: Provider() // 위젯 생성자 (타이밍 설정 가능)
        ) { entry in
            // 위젯에 표출될 뷰
            WGTestWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("내 위젯")
        .description("테스트 중임")
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    WGTestWidget()
} timeline: {
//    SimpleEntry(date: .now, configuration: .smiley)
//    SimpleEntry(date: .now, configuration: .starEyes)
    SimpleEntry(date: .now, texts: ["test", "testing", "testable"])
    SimpleEntry(date: .now, texts: ["test1", "testing2", "testable3"])
}

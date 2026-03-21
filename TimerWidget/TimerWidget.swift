import WidgetKit
import SwiftUI

// MARK: - Widget
@main
struct TimerWidget: Widget {
    let kind: String = "TimerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("취침까지 남은 시간")
        .description("취침까지 남은 시간을 보여줍니다.")
        .supportedFamilies([.systemMedium, .accessoryRectangular])
    }
}

// MARK: - 활동 시간 여부 판단
func isActiveTime(wake: Date, sleep: Date, now: Date = Date()) -> Bool {
    let calendar = Calendar.current
    
    let wakeComp = calendar.dateComponents([.hour, .minute], from: wake)
    let sleepComp = calendar.dateComponents([.hour, .minute], from: sleep)
    
    let todayWake = calendar.date(bySettingHour: wakeComp.hour!,
                                 minute: wakeComp.minute!,
                                 second: 0,
                                 of: now)!
    
    var todaySleep = calendar.date(bySettingHour: sleepComp.hour!,
                                  minute: sleepComp.minute!,
                                  second: 0,
                                  of: now)!
    
    if todaySleep <= todayWake {
        todaySleep = calendar.date(byAdding: .day, value: 1, to: todaySleep)!
    }
    
    return now >= todayWake && now < todaySleep
}

// MARK: - 남은 시간 퍼센트 (핵심)
func remainingPercent(wake: Date, sleep: Date, now: Date = Date()) -> Double {
    let calendar = Calendar.current
    
    let wakeComp = calendar.dateComponents([.hour, .minute], from: wake)
    let sleepComp = calendar.dateComponents([.hour, .minute], from: sleep)
    
    let todayWake = calendar.date(bySettingHour: wakeComp.hour!,
                                 minute: wakeComp.minute!,
                                 second: 0,
                                 of: now)!
    
    var todaySleep = calendar.date(bySettingHour: sleepComp.hour!,
                                  minute: sleepComp.minute!,
                                  second: 0,
                                  of: now)!
    
    if todaySleep <= todayWake {
        todaySleep = calendar.date(byAdding: .day, value: 1, to: todaySleep)!
    }
    
    // 활동시간 아닐 때는 0 (바 안보이게)
    if now < todayWake || now >= todaySleep {
        return 0.0
    }
    
    let total = todaySleep.timeIntervalSince(todayWake)
    let remaining = todaySleep.timeIntervalSince(now)
    
    return max(0, min(1, remaining / total))
}

// MARK: - 다음 취침 시각
func nextSleepDate(from sleep: Date, now: Date = Date()) -> Date {
    let calendar = Calendar.current
    let comp = calendar.dateComponents([.hour, .minute], from: sleep)
    
    let todaySleep = calendar.date(bySettingHour: comp.hour!,
                                   minute: comp.minute!,
                                   second: 0,
                                   of: now)!
    
    if todaySleep <= now {
        return calendar.date(byAdding: .day, value: 1, to: todaySleep)!
    }
    return todaySleep
}

// MARK: - Provider
struct Provider: TimelineProvider {
    let shared = UserDefaults(suiteName: "group.com.temp.daytimer")

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), wakeUp: Date(), sleep: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date(), wakeUp: getWakeUp(), sleep: getSleep()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let currentDate = Date()

        let sleepTime = getSleep()
        let wakeUpTime = getWakeUp()

        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            
            entries.append(SimpleEntry(date: entryDate, wakeUp: wakeUpTime, sleep: sleepTime))
        }

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }

    func getSleep() -> Date { shared?.object(forKey: "sleepTime") as? Date ?? Date() }
    func getWakeUp() -> Date { shared?.object(forKey: "wakeUpTime") as? Date ?? Date() }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let wakeUp: Date
    let sleep: Date
}

// MARK: - View
struct TimerWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        
        let now = Date()
        let isActive = isActiveTime(wake: entry.wakeUp, sleep: entry.sleep, now: now)
        let percent = remainingPercent(wake: entry.wakeUp, sleep: entry.sleep, now: now)
        
        let sleepDate = nextSleepDate(from: entry.sleep, now: now)
        let seconds = Int(sleepDate.timeIntervalSince(now))
        
        let hours = max(0, seconds / 3600)
        let minutes = max(0, (seconds % 3600) / 60)
        
        let pink = Color(red: 1.0, green: 0.2, blue: 0.6)
        
        if family == .accessoryRectangular {
            
            VStack {
                if isActive {
                    Text("\(hours):\(String(format: "%02d", minutes))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.pink)
                } else {
                    Text("수고하셨습니다")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .containerBackground(.clear, for: .widget)
            
        } else {
            
            VStack(spacing: 10) {
                if isActive {
                    
                    Text("취침까지 남은 시간은")
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text("\(hours)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(pink)
                        
                        Text("시간")
                            .foregroundColor(.gray)
                        
                        Text("\(String(format: "%02d", minutes))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(pink)
                        
                        Text("분")
                            .foregroundColor(.gray)
                    }
                    
                    SegmentBar(percent: percent)
                    
                } else {
                    
                    Text("수고하셨습니다.\n푹 쉬고 내일 다시 시작하세요 🌙")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .containerBackground(Color.black, for: .widget)
        }
    }
}

// MARK: - 퍼센트 바
struct SegmentBar: View {
    var percent: Double
    let totalSegments = 20
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<totalSegments, id: \.self) { index in
                let threshold = Double(index + 1) / Double(totalSegments)
                
                Rectangle()
                    .fill(indexColor(index))
                    .opacity(percent >= threshold ? 1 : 0.15)
                    .frame(height: 6)
                    .cornerRadius(2)
            }
        }
    }
    
    func indexColor(_ index: Int) -> Color {
        let t = Double(index) / Double(totalSegments)
        return Color(red: 1.0, green: 0.5 - t * 0.3, blue: 0.7 - t * 0.2)
    }
}

import SwiftUI
import WidgetKit

struct ContentView: View {
    @AppStorage("wakeUpTime") var wakeUpTime = Date()   // ✅ 추가
    @AppStorage("sleepTime") var sleepTime = Date()
    
    let groupID = "group.com.temp.daytimer"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("시간 설정") {
                    
                    // ✅ 기상 시간 추가
                    DatePicker("기상 시간", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("취침 시간", selection: $sleepTime, displayedComponents: .hourAndMinute)
                }
                
                Button("저장 및 위젯 업데이트") {
                    if let shared = UserDefaults(suiteName: groupID) {
                        shared.set(wakeUpTime, forKey: "wakeUpTime")   // ✅ 저장
                        shared.set(sleepTime, forKey: "sleepTime")
                        
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            }
            .navigationTitle("취침 타이머")
        }
    }
}

// 동일 함수
func nextSleepDate(from sleep: Date, now: Date = Date()) -> Date {
    let calendar = Calendar.current
    let sleepComponents = calendar.dateComponents([.hour, .minute], from: sleep)
    
    let todaySleep = calendar.date(bySettingHour: sleepComponents.hour!,
                                   minute: sleepComponents.minute!,
                                   second: 0,
                                   of: now)!
    
    if todaySleep <= now {
        return calendar.date(byAdding: .day, value: 1, to: todaySleep)!
    } else {
        return todaySleep
    }
}

#Preview {
    ContentView()
}

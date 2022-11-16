//
//  ViewController.swift
//  subtle
//
//  Created by iwheelbuy on 13.11.2022.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let vidFinishTime = Time("00:19:53,100")!
        let subFinishTime = Time("00:19:53,400")!

        let vidDuration = Double(vidFinishTime.ms)
        let subDuration = Double(subFinishTime.ms)
        let speed = vidDuration / subDuration
        update(episode: episode(11), speed: speed, write: true)
//        update(episode: episode(11), offset: 300, write: true)
    }

    func update(episode: String, offset: Int, write: Bool) {
        update(episode: episode, write: write) { value in
            return value.updated(offset: offset).line
        }
    }

    func update(episode: String, write: Bool, _ block: (Value) -> String?) {
        // < 1 видео короче чем субтитры
        // > 1 видео длиннее чем субтитры
        let url = Bundle.main.url(forResource: episode, withExtension: "srt")!
        var string = try! String(contentsOf: url)
        let lines = string
            .replacingOccurrences(of: "\r", with: "")
            .components(separatedBy: "\n")
        for line in lines {
            if let value = Value(line), let newLine = block(value) {
                print("~~|", line, newLine)
                string = string.replacingOccurrences(of: line, with: newLine)
            }
        }
        if write {
            do {
                let url = URL(fileURLWithPath: "/Users/iwheelbuy/Documents/subtitle/\(episode).srt")
                try string.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print(error)
            }
        }
    }

    func update(episode: String, speed: Double, write: Bool) {
        // < 1 видео короче чем субтитры
        // > 1 видео длиннее чем субтитры
        update(episode: episode, write: write) { value in
            return value.updated(speed: speed).line
        }
    }

    func episode(_ value: Int) -> String {
        return "brooklyn.nine.nine.s01e\(("0" + "\(value)").suffix(2)).web-dlrip.rus.eng.paramount.comedy"
    }
}

struct Value {

    let finish: Time
    let start: Time
    let line: String

    init(finish: Time, start: Time) {
        self.finish = finish
        self.start = start
        self.line = [start.line, finish.line].joined(separator: " --> ")
    }

    init?(_ line: String) {
        let a = line.components(separatedBy: " --> ")
        guard a.count == 2 else {
            return nil
        }
        guard let start = Time(a[0]) else {
            return nil
        }
        guard let finish = Time(a[1]) else {
            return nil
        }
        self.finish = finish
        self.start = start
        self.line = line
    }

    func updated(speed: Double) -> Value {
        return Value(
            finish: finish.ms.time(speed: speed),
            start: start.ms.time(speed: speed)
        )
    }

    func updated(offset: Int) -> Value {
        return Value(
            finish: finish.ms.time(offset: offset),
            start: start.ms.time(offset: offset)
        )
    }
}

struct Time {

    let hours: Number
    let milliseconds: Number
    let minutes: Number
    let seconds: Number
    let line: String

    init(hours: Number, milliseconds: Number, minutes: Number, seconds: Number) {
        self.hours = hours
        self.milliseconds = milliseconds
        self.minutes = minutes
        self.seconds = seconds
        self.line = [[hours.line, minutes.line, seconds.line].joined(separator: ":"), milliseconds.line].joined(separator: ",")
    }

    init?(_ line: String) {
        let a = line.components(separatedBy: ",")
        guard a.count == 2 else {
            return nil
        }
        guard let milliseconds = Number(a[1], size: 3) else {
            return nil
        }
        let b = a[0].components(separatedBy: ":")
        guard b.count == 3 else {
            return nil
        }
        guard let seconds = Number(b[2], size: 2) else {
            return nil
        }
        guard let minutes = Number(b[1], size: 2) else {
            return nil
        }
        guard let hours = Number(b[0], size: 2) else {
            return nil
        }
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
        self.milliseconds = milliseconds
        self.line = line
    }

    var ms: Int {
        let result = [
            hours.digits.joined * 60 * 60 * 1000,
            minutes.digits.joined * 60 * 1000,
            seconds.digits.joined * 1000,
            milliseconds.digits.joined
        ]
        return result.reduce(0, +)
    }
}

extension Int {

    func time(offset: Int) -> Time {
        let ms = self + offset
        return time(ms: ms)
    }

    func time(speed: Double) -> Time {
        let ms = Int(Double(self) * speed)
        return time(ms: ms)
    }

    func time(ms: Int) -> Time {
        let hours = number(ms: ms, upper: 24 * 60 * 60 * 1000, lower: 60 * 60 * 1000, size: 2)
        let milliseconds = number(ms: ms, upper: 1000, lower: 1, size: 3)
        let minutes = number(ms: ms, upper: 60 * 60 * 1000, lower: 60 * 1000, size: 2)
        let seconds = number(ms: ms, upper: 60 * 1000, lower: 1000, size: 2)
        return Time(hours: hours, milliseconds: milliseconds, minutes: minutes, seconds: seconds)
    }

    private func number(ms: Int, upper: Int, lower: Int, size: Int) -> Number {
        let value = (ms % upper) / lower
        var line = "\(value)"
        assert(line.count <= size)
        while line.count < size {
            line = "0" + line
        }
        let digits = line.compactMap({ Int("\($0)") })
        assert(digits.count == size)
        return Number(digits: digits, line: line)
    }
}

extension Array where Element == Int {

    var joined: Int {
        enumerated()
            .map({ (index, digit) in
                let decimal = pow(10, count - index - 1)
                let result = NSDecimalNumber(decimal: decimal).intValue
                return digit * result
            })
            .reduce(0, +)
    }
}

struct Number {

    let digits: [Int]
    let line: String

    init(digits: [Int], line: String) {
        self.digits = digits
        self.line = line
    }

    init?(_ line: String, size: Int) {
        let digits = line.compactMap({ Int("\($0)") })
        guard digits.count == line.count, digits.count == size else {
            return nil
        }
        self.digits = digits
        self.line = line
    }
}

import Foundation

struct RingBuffer<T> {
    private var buffer: [T?]
    private var writeIndex = 0
    private(set) var count = 0

    let capacity: Int

    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }

    mutating func append(_ element: T) {
        buffer[writeIndex] = element
        writeIndex = (writeIndex + 1) % capacity
        count = min(count + 1, capacity)
    }

    func toArray() -> [T] {
        guard count > 0 else { return [] }
        var result: [T] = []
        result.reserveCapacity(count)
        let start = count < capacity ? 0 : writeIndex
        for i in 0..<count {
            let index = (start + i) % capacity
            if let element = buffer[index] {
                result.append(element)
            }
        }
        return result
    }

    var latest: T? {
        guard count > 0 else { return nil }
        let index = (writeIndex - 1 + capacity) % capacity
        return buffer[index]
    }

    var isEmpty: Bool { count == 0 }

    mutating func clear() {
        buffer = Array(repeating: nil, count: capacity)
        writeIndex = 0
        count = 0
    }
}

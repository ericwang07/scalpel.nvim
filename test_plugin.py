import collections
import time


class Api:
    def __init__(self, limit, time_window):
        self._limit = limit
        self._time_window = time_window
        self._call_queue = collections.deque()

    def call(self):
        now = time.time()
        while self._call_queue and self._call_queue[0] + self._time_window <= now:
            self._call_queue.popleft()

        if len(self._call_queue) >= self._limit:
            print("Error: API limit reached")
            return 1

        self._call_queue.append(now)
        print("Success! API called")
        return 0


if __name__ == "__main__":
    my_api = Api(limit=3, time_window=1)
    for i in range(5):
        my_api.call()
        time.sleep(1)

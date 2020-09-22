# -------------------------------------------------------------------------------------------------
#  Licensed under the GNU Lesser General Public License Version 3.0 (the "License");
#  You may not use this file except in compliance with the License.
#  You may obtain a copy of the License at https://www.gnu.org/licenses/lgpl-3.0.en.html
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
# -------------------------------------------------------------------------------------------------

from collections import deque

from cpython.datetime cimport datetime
from cpython.datetime cimport timedelta

from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.core.datetime cimport is_datetime_utc
from nautilus_trader.model.objects cimport Price


cdef class WindowedMinMaxPrices:
    """
    Over the course of a defined lookback window, efficiently keep track
    of the min/max values currently in the window.
    """

    def __init__(self, timedelta lookback not None):
        """
        Initialize a new instance of the WindowedMinMaxPrices class.

        Parameters
        ----------
        lookback : timedelta
            The look back duration in time.
        """
        self.lookback = lookback
        # Set the min/max marks as None until we have data
        self.min_price = None
        self.max_price = None
        # Initialize the deques
        self._min_prices = deque()
        self._max_prices = deque()

    cpdef void add_price(self, datetime ts, Price price):
        """
        Given a price at a UTC timestamp, insert it into the structures and
        update our running min/max values.
        """
        Condition.true(is_datetime_utc(ts), "`ts` is a tz-aware UTC")

        # Expire old prices
        cdef datetime cutoff = ts - self.lookback
        self._expire_stale_prices_by_cutoff(self._min_prices, cutoff)
        self._expire_stale_prices_by_cutoff(self._max_prices, cutoff)

        # Append to the min/max structures
        self._add_min_price(ts, price)
        self._add_max_price(ts, price)

        # Pull out the min/max
        self.min_price = min([p[1] for p in self._min_prices])
        self.max_price = max([p[1] for p in self._max_prices])

    cpdef void reset(self):
        """Reset the class to like-new."""
        # Set the min/max marks as None until we have data
        self.min_price = None
        self.max_price = None
        # Clear the deques
        self._min_prices.clear()
        self._max_prices.clear()

    cdef inline void _expire_stale_prices_by_cutoff(
        self,
        object ts_prices,
        datetime cutoff
    ):
        """Drop items that are older than the cutoff"""
        while ts_prices and ts_prices[0][0] < cutoff:
            ts_prices.popleft()

    cdef inline void _add_min_price(self, datetime ts, Price price):
        """Handle appending to the min deque"""
        # Pop front elements that are less than or equal (since we want the max ask)
        while self._min_prices and self._min_prices[-1][1] <= price:
            self._min_prices.pop()

        # Pop back elements that are less than or equal to the new ask
        while self._min_prices and self._min_prices[0][1] <= price:
            self._min_prices.popleft()

        self._min_prices.append((ts, price))

    cdef inline void _add_max_price(self, datetime ts, Price price):
        """Handle appending to the max deque"""
        # Pop front elements that are less than or equal (since we want the max bid)
        while self._max_prices and self._max_prices[-1][1] <= price:
            self._max_prices.pop()

        # Pop back elements that are less than or equal to the new bid
        while self._max_prices and self._max_prices[0][1] <= price:
            self._max_prices.popleft()

        self._max_prices.append((ts, price))

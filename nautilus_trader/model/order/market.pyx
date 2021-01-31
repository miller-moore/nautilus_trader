# -------------------------------------------------------------------------------------------------
#  Copyright (C) 2015-2021 Nautech Systems Pty Ltd. All rights reserved.
#  https://nautechsystems.io
#
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

from cpython.datetime cimport datetime

from nautilus_trader.core.constants cimport *  # str constants only
from nautilus_trader.core.correctness cimport Condition
from nautilus_trader.core.uuid cimport UUID
from nautilus_trader.model.c_enums.order_side cimport OrderSide
from nautilus_trader.model.c_enums.order_side cimport OrderSideParser
from nautilus_trader.model.c_enums.order_type cimport OrderType
from nautilus_trader.model.c_enums.order_type cimport OrderTypeParser
from nautilus_trader.model.c_enums.time_in_force cimport TimeInForce
from nautilus_trader.model.c_enums.time_in_force cimport TimeInForceParser
from nautilus_trader.model.events cimport OrderAmended
from nautilus_trader.model.events cimport OrderFilled
from nautilus_trader.model.events cimport OrderInitialized
from nautilus_trader.model.identifiers cimport ClientOrderId
from nautilus_trader.model.identifiers cimport StrategyId
from nautilus_trader.model.identifiers cimport Symbol
from nautilus_trader.model.objects cimport Quantity
from nautilus_trader.model.order.base cimport Order


cdef set _MARKET_ORDER_VALID_TIF = {
    TimeInForce.GTC,
    TimeInForce.IOC,
    TimeInForce.FOK,
}


cdef class MarketOrder(Order):
    """
    A market order is an order to buy or sell an instrument immediately. This
    type of order guarantees that the order will be executed, but does not
    guarantee the execution price. A market order generally will execute at or
    near the current bid (for a sell order) or ask (for a buy order) price. The
    last-traded price is not necessarily the price at which a market order will
    be executed.
    """
    def __init__(
        self,
        ClientOrderId cl_ord_id not None,
        StrategyId strategy_id not None,
        Symbol symbol not None,
        OrderSide order_side,
        Quantity quantity not None,
        TimeInForce time_in_force,
        UUID init_id not None,
        datetime timestamp not None,
    ):
        """
        Initialize a new instance of the `MarketOrder` class.

        Parameters
        ----------
        cl_ord_id : ClientOrderId
            The client order identifier.
        strategy_id : StrategyId
            The strategy identifier associated with the order.
        symbol : Symbol
            The order symbol.
        order_side : OrderSide (Enum)
            The order side (BUY or SELL).
        quantity : Quantity
            The order quantity (> 0).
        init_id : UUID
            The order initialization event identifier.
        timestamp : datetime
            The order initialization timestamp.

        Raises
        ------
        ValueError
            If quantity is not positive (> 0).
        ValueError
            If order_side is UNDEFINED.
        ValueError
            If time_in_force is UNDEFINED.
        ValueError
            If time_in_force is other than GTC, IOC or FOK.

        """
        Condition.positive(quantity, "quantity")
        Condition.true(time_in_force in _MARKET_ORDER_VALID_TIF, "time_in_force is GTC, IOC or FOK")

        cdef OrderInitialized init_event = OrderInitialized(
            cl_ord_id=cl_ord_id,
            strategy_id=strategy_id,
            symbol=symbol,
            order_side=order_side,
            order_type=OrderType.MARKET,
            quantity=quantity,
            time_in_force=time_in_force,
            event_id=init_id,
            event_timestamp=timestamp,
            options={},
        )

        super().__init__(init_event)

    @staticmethod
    cdef MarketOrder create(OrderInitialized event):
        """
        Return an order from the given initialized event.

        Parameters
        ----------
        event : OrderInitialized
            The event to initialize with.

        Returns
        -------
        MarketOrder

        Raises
        ------
        ValueError
            If event.order_type is not equal to OrderType.MARKET.

        """
        Condition.not_none(event, "event")
        Condition.equal(event.order_type, OrderType.MARKET, "event.order_type", "OrderType")

        return MarketOrder(
            cl_ord_id=event.cl_ord_id,
            strategy_id=event.strategy_id,
            symbol=event.symbol,
            order_side=event.order_side,
            quantity=event.quantity,
            time_in_force=event.time_in_force,
            init_id=event.id,
            timestamp=event.timestamp,
        )

    cdef str status_string_c(self):
        return (f"{OrderSideParser.to_str(self.side)} {self.quantity.to_str()} {self.symbol} "
                f"{OrderTypeParser.to_str(self.type)} "
                f"{TimeInForceParser.to_str(self.time_in_force)}")

    cdef void _amended(self, OrderAmended event) except *:
        raise NotImplemented("Cannot amend a market order")

    cdef void _filled(self, OrderFilled event) except *:
        self.id = event.order_id
        self.position_id = event.position_id
        self.strategy_id = event.strategy_id
        self._execution_ids.append(event.execution_id)
        self.execution_id = event.execution_id
        self.filled_qty = Quantity(self.filled_qty + event.fill_qty)
        self.filled_timestamp = event.timestamp
        self.avg_price = self._calculate_avg_price(event.fill_price, event.fill_qty)

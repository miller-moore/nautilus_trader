![Nautech Systems](https://github.com/nautechsystems/nautilus_trader/blob/master/docs/artwork/ns-logo.png?raw=true "logo")

----------

# NautilusTrader

![Build Status](![.github/workflows/build](https://github.com/nautechsystems/nautilus_trader/workflows/.github/workflows/build/badge.svg))
![Python Supported](https://img.shields.io/pypi/pyversions/nautilus_trader)
![Stable Version](https://img.shields.io/pypi/v/nautilus_trader)

## Introduction

NautilusTrader is an algorithmic trading platform allowing quantitative traders
the ability to backtest portfolios of automated trading strategies on historical
data with an event-driven engine, and also trade those strategies live in a
production grade environment. The project heavily utilizes Cython to provide
type safety and performance through C extension modules. The libraries can be
accessed from both pure Python and Cython.

Cython is a compiled programming language that aims to be a superset of the
Python programming language, designed to give C-like performance with code that
is written mostly in Python with optional additional C-inspired syntax.
> https://cython.org

To run code or tests from the cloned repo, first compile the C extensions for the package.
Note that initial compilation may take several minutes due to the quantity of extensions.

    $ python setup.py build_ext --inplace

NautilusTrader has been open-sourced from working production code, and forms
part of a larger distributed system. The messaging API can interface with the Nautilus platform
where `Data` and `Execution` services implemented with C# .NET Core allow this trading framework
to integrate with `FIX4.4` connections for data ingestion and trade management.

> https://github.com/nautechsystems/Nautilus

There is currently a large effort to develop improved documentation.

## Features
* **Fast:** C level speed and type safety provided through Cython. ZeroMQ message transport, MsgPack wire serialization.
* **Flexible:** Any FIX or REST broker API can be integrated into the platform, with no changes to your strategy scripts.
* **Distributed:** Pluggable into distributed system architectures due to the efficient message passing API.
* **Backtesting:** Multiple instruments and strategies simultaneously with historical tick and/or bar data.
* **AI Agent Training:** Backtest engine fast enough to be used to train AI trading agents (RL/ES).
* **Teams Support:** Support for teams with many trader boxes. Suitable for professional algorithmic traders or hedge funds.
* **Cloud Enabled:** Flexible deployment schemas - run with data and execution services embedded on a single box, or deploy across many boxes in a networked or cloud environment.
* **Encryption:** Built-in Curve encryption support with ZeroMQ. Run trading boxes remote from co-located data and execution services.

## Values
* Reliability
* Testability
* Performance
* Modularity
* Maintainability
* Scalability

[API Documentation](https://nautechsystems.io/nautilus/api)

## Installation
Stable version;

    $ pip install nautilus_trader


Latest version;

    $ pip install -U git+https://github.com/nautechsystems/nautilus_trader


## Encryption
For effective remote deployment of a live ```TradingNode``` encryption keys must be generated by the
client trader. The currently supported encryption scheme is that which is built into ZeroMQ
being Curve25519 elliptic curve algorithms. This allows perfect forward security with ephemeral keys
being exchanged per connection. The public ```server.key``` must be shared with the trader ahead of
time and contained in the ```keys\``` directory (see below).

To generate a new client key pair from a python console or .py run the following;

    import zmq.auth
    from pathlib import Path

    keys_dir = 'path/to/your/keys'
    Path(keys_dir).mkdir(parents=True, exist_ok=True)

    zmq.auth.create_certificates(keys_dir, 'client')

## Live Deployment
The trader must assemble a directory including the following;

- ```config.json``` for configuration settings
- ```keys/``` directory containing the ```client.key_secret``` and ```server.key```
- ```launch.py``` referring to the strategies to run
- trading strategy python or cython files

## Development
[Development Documentation](docs/development/)

We recommend the PyCharm Professional edition IDE as it interprets Cython syntax.
Unfortunately the Community edition will not interpret Cython syntax.

> https://www.jetbrains.com/pycharm/

To run the tests, first compile the C extensions for the package. Note that
initial compilation may take several minutes due to the quantity of extensions.

    $ python setup.py build_ext --inplace

All tests can be run via the `run_tests.sh` script, or through pytest.

## Support
Please direct all questions, comments or bug reports to info@nautechsystems.io

Copyright (C) 2015-2020 Nautech Systems Pty Ltd. All rights reserved.

> https://nautechsystems.io

![Cython](https://github.com/nautechsystems/nautilus_trader/blob/master/docs/artwork/cython-logo.png?raw=true "cython")

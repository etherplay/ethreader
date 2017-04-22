ethreader allows to programmatically inspect [ethereum](https://ethereum.org) transactions of a a given contract address.

ethreader use the abi of that contract to decode the input and thus allow you to filter and answer question regarding the transactions using method names and parameters. For now it use [etherscan](https://etherscan.io) api but we plan to support other method later such as direct node transaction parsing.

This tool allows use at Etherplay to analyse our contract's transactions data : how many players started a game, how many submitted a score....
It can also answer more complex question such as how long in average the player took to submit a transaction have a game is over.

ethreader has been built using [Haxe](https://haxe.org/) but can be used in both javascript and Haxe.

You can find an example for javascript in "test.js" and for Haxe in test/src/TestAll.hx

The tool is functional but it is still a work in progress.



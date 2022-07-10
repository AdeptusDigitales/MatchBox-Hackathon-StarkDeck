# CCG Style Draft Mode Implementation in Cairo

## Game Description

The game is a re-creation of the draft format used in the popular collectable card game Hearthstone.
Two players draft a deck of cards and then proceed to play against each other.

### Project Setup

The game is fully playable using the `./src/main.cairo` contract.</br>
However a game client should be used when playing the game.
The `demo` video file demonstrates the usage in combination with a game client.</br>
The game client was created with Unreal Engine 5. As there is no C++ library for the StarkNet specific signing/hashing functions we used a seperate server, that the game sends it's transaction instructions to via a http request. The server then uses starknet.py to perform all the signing, signing and executes the transactions. It also performs all other contract queries. </br>
```diff
-IMPORTANT
```
The server was **NOT** created within the time frame of the Hackathon. The PNGs used for the playing cards and the blueprints that interact with the server where also created before the hackathon.

The best way to understand what's going on in the code is by watching:
https...

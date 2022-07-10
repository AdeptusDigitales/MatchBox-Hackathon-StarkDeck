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

### The Game

TL;DR </br>
Each player starts the game with ~20 health.</br>
The playing cards have the following stats: Cost,Attack,Health.</br>
Players use the cards to reduce destoy their enemies cards and deal damage to the enemies health.</br>
The player whose health reaches 0 first, loses the game.

### The Draft Procedure:

A player draws three random cards. </br>
They select one of them and ads it to their deck. They discard the other two cards.</br>
The process is repeated until the player has reached the deck size limit (usualy around ~30 cards).</br>
When both players have reached their deck limit, they proceed to play a match against each other.</br>
Both players don't know what their opponents cards are until they play them.

## Execution in Cairo

### Storage

The cairo contract has to hold the following information:
1) Cards in the hand of each player
2) Cards that are currently played on the Board
3) Damage dealt to each played card and player
4) The "deck". Cards that can be drawn by each player (decreases with each card that is being drawn)
5) The originally drafted cards

1, 2, 3 and 4 are packed into one felt.

5 is stored using two mappings per player... I'm sure this can be done more efficient.

See game_settings.cairo for more info regarding the storage setup.

### Secret Draft

The main challange of creating this game mode was that each player has to draft their deck randomly before the game, without the enemy knowing which cards they have drawn. The individual cards are only revealed once they play them. </br>
This is achieved with the following process:

A player, that joins the game stores their private key that they will be using throughout the game.
A player creates a random number on-chain (We use a pseudo random number generator. Hopefully some gigabrain finds a good solution for random numbers in the future).<br>
The random number is stored in the smart contract.</br>
Off-chain, the player hashes the random number and generates a signature using the hash and their private key.</br>
They use the function `get_draft_from_sig()` in `main.cairo` to extract 9 numbers from the signature that represent the 3 randomly drawn cards.</br>
E.g. 678201 means the player has drawn the cards with the IDs: 67, 82, and 01. As we only have 20 cards, the IDs are normalized to the range of 0-19.</br>
The player makes their selection by storing the index of the card they have choosen.</br>
Later on 


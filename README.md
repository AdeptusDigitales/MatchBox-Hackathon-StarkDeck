# CCG Style Draft Mode Implementation in Cairo

## Game Description

The game is a re-creation of the draft format used in the popular collectable card game Hearthstone.
Two players draft a deck of cards and then proceed to play against each other.

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
1.) Cards in the hand of each player
2.) Cards that are currently played on the Board
3.) Damage dealt to each played card and player
4.) The "deck". Cards that can be drawn by each player (decreases with each card that is being drawn)
5.) The originally drafted cards

1, 2, 3 and 4 are packed into one felt.

5 is stored using two mappings per player... I'm sure this can be done more efficient.

See game_settings.cairo for more info regarding the storage setup.

### Secret Draft

The main challange of this game mode is that each player has to draft their deck randomly before the game, without the enemy knowing which cards they have drawn. The individual cards are only revealed once they play them. </br>
This is achieved with the following process:

A player, that joins the game stores their private key that they will be using throughout the game.
A player creates a random number on chain (We use a pseudo random number generator. Hopefully some gigabrain finds a good solution for random numbers in the future).<br>
The random number is stored in the smart contract.
Off-chain, the player hashes the random number and creates a signature.
They use the following function to 

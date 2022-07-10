# CCG Style Draft Mode Implementation in Cairo

## Game Description

The game is a re-creation of the draft format used in the popular collectable card game Hearthstone.</br>
The game is fully playable using only a smart-contract that is deployed on StarkNet.
Two players draft a deck of cards and then proceed to play against each other.</br>
A demonstration of the Draft mode can be viewed at:</br>
https://youtu.be/YFlvWvlrB7g
Limited to 5min as per rules of the Hackathon.

### Project Setup

The game is fully playable using the `./src/main.cairo` contract.</br>
However a game client should be used when playing the game.
The provided video demonstrates the usage with a game client.</br>
The game client was created with Unreal Engine 5. As there is no C++ library for the StarkNet specific signing/hashing functions we used a seperate server, that the game sends it's transaction instructions to via a http request. The server then uses starknet.py to perform all the signing, hashing and executes the transactions. It also performs all other contract queries. </br>
```diff
-IMPORTANT
```
The server was **NOT** created within the time frame of the Hackathon. The PNGs used for the playing cards and the blueprints that interact with the server where also created before the hackathon. Parts of the library `board_editor.cairo` (which transforms felts to dictionaries and back) where also created before the official start of the hackathon, so please treat that library as an external library that isn't part of the submission.

### The Game

TL;DR </br>
Both players don't know what their opponents cards are until they play them. </br>
Each player starts the game with ~20 health.</br>
The cards have the following stats: Cost,Attack,Health.</br>
Players use the cards to destoy their enemies cards and deal damage to the enemies health.</br>
The player whose health reaches 0 first, loses the game.

**The main ways to interact with the contract are:**

`join_lobby()` -> your public key is stored in the contract and you have joined the game as either player 0 or player 1.

`get_card_draft()` -> you generate the very first 3 cards from which to choose from.

`select_card()` -> you select one of the three cards and generate the next 3 cards.

`initial_draw()` -> you draw 3 cards from you deck to your hand

`post_action()` -> This function is used to either: Place a card or use a card to attack. Your turn will end after the function is called, and a random number will be generated that the other player uses to draw a card.

### The Draft Procedure:

A player draws three random cards. </br>
They select one of them and add it to their deck. They discard the other two cards.</br>
The process is repeated until the player has reached the deck size limit (usualy around ~30 cards).</br>
When both players have reached their deck limit, they proceed to play a match against each other.</br>
Both players don't know what their opponents cards are until they play them.

### Storage

The cairo contract has to store the following information:</br>
1) Cards in the hand of each player
2) Cards that are currently played on the Board
3) Damage dealt to each played card and player
4) The "deck". Cards that can be drawn by each player (decreases with each card that is being drawn)
5) The originally drafted cards

1, 2, 3 and 4 are packed into one felt.

See `game_settings.cairo` for more info regarding the storage setup.

### Secret Draft

The main challange of creating this game mode was that each player has to draft their deck randomly before the game without the enemy knowing which cards they have drawn. The individual cards are only revealed once they play them. </br>
This is achieved with the following process:</br>

A player, that joins the game stores their public key that they will be using throughout the game in the game contract.
A player creates a random number on-chain (We use a pseudo random number generator. Hopefully some gigabrain finds a good solution for random numbers in the future).<br>
The random number is stored in the game contract.</br>
Off-chain, the player hashes the random number and creates a signature.</br>
They use the function `get_draft_from_sig()` in `main.cairo` to extract 6 numbers from the signature that represent the 3 randomly drawn cards.</br>
E.g. 678201 means the player has drawn the cards with the IDs: 67, 82, and 01. As we only have 20 cards, the IDs are normalized to the range of 0-19.</br>
The Card IDs are mapped to card stats: HP/Attack/Cost, these are set once by the creator of the lobby and not changed afterwards.</br>
The player makes their selection by storing the index of the card they have choosen. So from the number 678201, if they select card 01, they store the index 2, as they have hosen the 3rd card of the draft.</br>

The final stored draft for one player looks something like this:

0 Card_Pick(random_number=279634723694, pick_index=0)

1 Card_Pick(random_number=289583467234, pick_index=2)

2 Card_Pick(random_number=028384723847, pick_index=0)

3 Card_Pick(random_number=018932473727, pick_index=1)

...

### Drawing a Card

A card is drawn to a players hand by generating a random number. We take the last two digits of that number. Those represent the index of our draft.
So if we generated the number 06, that means that we have drawn the card which we selected at the 7th (our index starts at 0) draw during the drafting phase. 
This means our enemy only knows that we have drawn what ever card we drew during the 7th turn of our draft, but we know exactly which card that was (this requires us remembering what card we drew or to write that card down when we selected it. This task should be taken care of by a client side interface that is used to interact with the game contract).

### Reveiling a Card

Once a card is placed on the board, it has to be revealed. The player only has to provide the signature that they generated when drawing the specific card during the drafting phase and the hand index of the card they want to play. Using the hand index, the smart contract can fetch the random number that was used to determine the 3 cards drawn in the draft. Using the players public key and that stored random number they can validate that provided signature is valid. From there, using the stored picked-card index (2 in our previous example) the contract can generate the card that we played (in our example that would be 01). 

%lang starknet

from starkware.cairo.common.bitwise import bitwise_and, bitwise_or, bitwise_xor
from starkware.cairo.common.cairo_builtins import (BitwiseBuiltin, HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.math import assert_le, split_felt, unsigned_div_rem, assert_not_zero
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.cairo.common.default_dict import default_dict_new,default_dict_finalize
from starkware.cairo.common.dict import (dict_write, dict_read)
from starkware.cairo.common.dict_access import DictAccess
from starkware.starknet.common.syscalls import get_caller_address

from interfaces.IAccount import IAccount
#Taken from https://github.com/gaetbout/starknet-felt-packing by gaetbout
from lib.starknet_felt_packing_git.contracts.bits_manipulation import external as bits_manipulation
#Taken and and adjusted from https://github.com/milancermak/xoroshiro-cairo by milancermak 
from src.lib.random import (Random, State)
from src.lib.board_editor import Board
#Have a look at this lib to understand the storage setup
from src.lib.game_settings import (
    Attack_action,
    Placement_action,
    HERO_HP,
    NUMBER_OF_UNIQUE_CARDS,
    DRAFT_LENGTH,
    DECK_LEN_SIZE,
    HAND0_POSITION,
    BOARD0_POSITION,
    DAMAGE0_POSITION,
    HAND1_POSITION,
    BOARD1_POSITION,
    DAMAGE1_POSITION,
    TURN_COUNTER_POSITION,
    HAND_SIZE,
    BOARD_SIZE,
    DAMAGE_SIZE,
    DAMAGE_AMOUNT_SIZE,
    DECK_INDEX_SIZE,
    TURN_COUNTER_SIZE,
    CARD_ID_SIZE,
    DRAFT_ID_SIZE,
    MAX_HAND_CARDS,
    MAX_BOARD_CARDS,
    DECK0_POSITION,
    DECK1_POSITION
)

#
# Structs
#

struct Card_Pick:
    member random_number : felt
    member index : felt
end

struct Card:
    member cost : felt
    member attack : felt
    member health : felt
end

struct Signature:
    member one : felt
    member two : felt
end

#
#Game Storage
#

@storage_var
func players(index: felt)->(player_public_key: felt):
end

@storage_var
func cards(card_id: felt)->(card: Card):
end

#See game_settings.cairo for breakdown of the board storage
@storage_var
func board()->(board:felt): 
end

#
#Draft Storage
#

@storage_var
func draft_player0_selection(index: felt)->(card_pick: Card_Pick):
end

@storage_var
func draft_player1_selection(index: felt)->(card_pick: Card_Pick):
end

@storage_var
func draft_player0_selection_len()->(len: felt):
end

@storage_var
func draft_player1_selection_len()->(len: felt):
end

#
#Constructor
#

@constructor
func constructor{
    syscall_ptr : felt*, 
    bitwise_ptr : BitwiseBuiltin*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}():
    alloc_locals

    #Init random number generator
    let (s0) = Random.splitmix64(56315471834167356542763546752736) #SEED
    let (s1) = Random.splitmix64(s0)
    let s = State(s0=s0, s1=s1)
    Random.set_state(s)

    #Set initial draft length (is probably 0 by default...so maybe remove)
    draft_player0_selection_len.write(0)
    draft_player1_selection_len.write(0)

    #SET INITIAL BOARD FELT
    #
        #HandPlayer0
        #let (board0v1) = bits_manipulation.actual_set_element_at(0, 0, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v2) = bits_manipulation.actual_set_element_at(board0v1, CARD_ID_SIZE*1, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v3) = bits_manipulation.actual_set_element_at(board0v2, CARD_ID_SIZE*2, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v4) = bits_manipulation.actual_set_element_at(board0v3, CARD_ID_SIZE*3, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v5) = bits_manipulation.actual_set_element_at(board0v4, CARD_ID_SIZE*4, CARD_ID_SIZE, DRAFT_LENGTH)
        #BoardPlayer0
        #let (board0v6) = bits_manipulation.actual_set_element_at(board0v5, CARD_ID_SIZE*5, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v7) = bits_manipulation.actual_set_element_at(board0v6, CARD_ID_SIZE*6, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v8) = bits_manipulation.actual_set_element_at(board0v7, CARD_ID_SIZE*7, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v9) = bits_manipulation.actual_set_element_at(board0v8, CARD_ID_SIZE*8, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v10) = bits_manipulation.actual_set_element_at(board0v9, CARD_ID_SIZE*9, CARD_ID_SIZE, DRAFT_LENGTH)
        #DamagePlayer0
        #let (board0v11) = bits_manipulation.actual_set_element_at(board0v10, CARD_ID_SIZE*10, CARD_ID_SIZE, 0)
        #let (board0v12) = bits_manipulation.actual_set_element_at(board0v11, CARD_ID_SIZE*11, CARD_ID_SIZE, 0)
        #let (board0v13) = bits_manipulation.actual_set_element_at(board0v12, CARD_ID_SIZE*12, CARD_ID_SIZE, 0)
        #let (board0v14) = bits_manipulation.actual_set_element_at(board0v13, CARD_ID_SIZE*13, CARD_ID_SIZE, 0)
        #let (board0v15) = bits_manipulation.actual_set_element_at(board0v14, CARD_ID_SIZE*14, CARD_ID_SIZE, 0)
        #let (board0v16) = bits_manipulation.actual_set_element_at(board0v15, CARD_ID_SIZE*15, CARD_ID_SIZE, 0)
        #HandPlayer1
        #let (board0v17) = bits_manipulation.actual_set_element_at(board0v16, CARD_ID_SIZE*16, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v18) = bits_manipulation.actual_set_element_at(board0v17, CARD_ID_SIZE*17, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v19) = bits_manipulation.actual_set_element_at(board0v18, CARD_ID_SIZE*18, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v20) = bits_manipulation.actual_set_element_at(board0v19, CARD_ID_SIZE*19, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v21) = bits_manipulation.actual_set_element_at(board0v20, CARD_ID_SIZE*20, CARD_ID_SIZE, DRAFT_LENGTH)
        #BoardPlayer1
        #let (board0v22) = bits_manipulation.actual_set_element_at(board0v21, CARD_ID_SIZE*21, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v23) = bits_manipulation.actual_set_element_at(board0v22, CARD_ID_SIZE*22, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v24) = bits_manipulation.actual_set_element_at(board0v23, CARD_ID_SIZE*23, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v25) = bits_manipulation.actual_set_element_at(board0v24, CARD_ID_SIZE*24, CARD_ID_SIZE, DRAFT_LENGTH)
        #let (board0v26) = bits_manipulation.actual_set_element_at(board0v25, CARD_ID_SIZE*25, CARD_ID_SIZE, DRAFT_LENGTH)
        #DamagePlayer1
        #let (board0v27) = bits_manipulation.actual_set_element_at(board0v26, CARD_ID_SIZE*26, CARD_ID_SIZE, 0)
        #let (board0v28) = bits_manipulation.actual_set_element_at(board0v27, CARD_ID_SIZE*27, CARD_ID_SIZE, 0)
        #let (board0v29) = bits_manipulation.actual_set_element_at(board0v28, CARD_ID_SIZE*28, CARD_ID_SIZE, 0)
        #let (board0v30) = bits_manipulation.actual_set_element_at(board0v29, CARD_ID_SIZE*29, CARD_ID_SIZE, 0)
        #let (board0v31) = bits_manipulation.actual_set_element_at(board0v30, CARD_ID_SIZE*30, CARD_ID_SIZE, 0)
        #let (board0v32) = bits_manipulation.actual_set_element_at(board0v31, CARD_ID_SIZE*31, CARD_ID_SIZE, 0)
        #TurnCounter
        #let (board0v33) = bits_manipulation.actual_set_element_at(board0v32, CARD_ID_SIZE*32, CARD_ID_SIZE, 1) #Set turn counter to 1
        #Deck0
        #let (board0v34) = bits_manipulation.actual_set_element_at(board0v33, CARD_ID_SIZE*33, CARD_ID_SIZE, 0)
        #let (board0v35) = bits_manipulation.actual_set_element_at(board0v34, CARD_ID_SIZE*34, CARD_ID_SIZE, 1)
        #let (board0v36) = bits_manipulation.actual_set_element_at(board0v35, CARD_ID_SIZE*35, CARD_ID_SIZE, 2)
        #let (board0v37) = bits_manipulation.actual_set_element_at(board0v36, CARD_ID_SIZE*36, CARD_ID_SIZE, 3)
        #let (board0v38) = bits_manipulation.actual_set_element_at(board0v37, CARD_ID_SIZE*37, CARD_ID_SIZE, 4)
        #Deck0 Length
        #let (board0v39) = bits_manipulation.actual_set_element_at(board0v38, CARD_ID_SIZE*38, CARD_ID_SIZE, DRAFT_LENGTH)
        #Deck1
        #let (board0v40) = bits_manipulation.actual_set_element_at(board0v39, CARD_ID_SIZE*39, CARD_ID_SIZE, 0)
        #let (board0v41) = bits_manipulation.actual_set_element_at(board0v40, CARD_ID_SIZE*40, CARD_ID_SIZE, 1)
        #let (board0v42) = bits_manipulation.actual_set_element_at(board0v41, CARD_ID_SIZE*41, CARD_ID_SIZE, 2)
        #let (board0v43) = bits_manipulation.actual_set_element_at(board0v42, CARD_ID_SIZE*42, CARD_ID_SIZE, 3)
        #let (board0v44) = bits_manipulation.actual_set_element_at(board0v43, CARD_ID_SIZE*43, CARD_ID_SIZE, 4)
        #Deck1 Length
        #let (board0v45) = bits_manipulation.actual_set_element_at(board0v44, CARD_ID_SIZE*44, CARD_ID_SIZE, DRAFT_LENGTH)
        
        #board0v45 = 8640648889513761125820918182833005483182668222901574828734735881381

    board.write(8640648889513761125820918182833005483182668222901574828734735881381)
    
    return ()
end

############################
#           Views          #
############################

@view
func get_draft{
    syscall_ptr : felt*,  
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_index: felt, _player: felt)->(card_pick: Card_Pick):
    if _player == 0:
        let (card_pick) = draft_player0_selection.read(_index)
        return(card_pick)
    end
    let (card_pick) = draft_player1_selection.read(_index)
    return(card_pick)
end

@view
func get_players{
    syscall_ptr : felt*,  
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}()->(player0: felt, player1: felt):
    let (player0) = players.read(0)
    let (player1) = players.read(1)
    return(player0,player1)
end

@view 
func get_board{
    syscall_ptr : felt*,  
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}()->(board: felt):
    let (current_board) = board.read()
    return(current_board)
end

@view
func is_draft_complete{
    syscall_ptr : felt*,  
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}()->(is_complete: felt):
    
    let (len0) = draft_player1_selection_len.read()
    if len0 != DRAFT_LENGTH:
        return(0)
    end
    let (len1) = draft_player0_selection_len.read()
    if len1 != DRAFT_LENGTH:
        return(0)
    end

    return(1)
end

#Method used to generate the draft from a signature
#We would usualy just get the last 9 digits of the signature, 
#but the signature is to large to perform an unsigned_div_rem. So we split the sig first.
@view 
func get_draft_from_sig{
    syscall_ptr : felt*,  
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_sig0: felt)->(draft: felt):

    let (high, low) = split_felt(_sig0)
    let (left_side,_) = unsigned_div_rem(low,1000000) 
    tempvar draft = low - left_side * 1000000

    return(draft)
end

#Fetches players deck length/size
@view
func get_deck_len{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_player: felt)->(deck_len: felt):
    alloc_locals
    local deck_position : felt

    if _player == 0:
        deck_position = DECK0_POSITION
    else:
        deck_position = DECK1_POSITION
    end

    #Get player deck
    let (current_board) = board.read()

    #Get deck length
    let (deck_len) = bits_manipulation.actual_get_element_at(
        input=current_board,
        at=deck_position + (DRAFT_LENGTH * DECK_INDEX_SIZE),
        number_of_bits = DECK_LEN_SIZE
    )
    return(deck_len)
end    

#Fetches a players hand
@view 
func get_hand{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_player: felt)->(hand_cards_len: felt,hand_cards: felt*):
    alloc_locals

    let(current_board) = board.read()

    if _player == 0:
        let (local Hand0_start) = default_dict_new(default_value=MAX_HAND_CARDS)

        let (Hand0: DictAccess*) = Board.felt_to_dict(current_board, Hand0_start, HAND0_POSITION, DRAFT_ID_SIZE, 0, MAX_HAND_CARDS)

        let (hand_cards : felt*) = alloc()
        let (card0) = dict_read{dict_ptr=Hand0}(0)
        hand_cards[0] = card0
        let (card1) = dict_read{dict_ptr=Hand0}(1)
        hand_cards[1] = card1
        let (card2) = dict_read{dict_ptr=Hand0}(2)
        hand_cards[2] = card2
        let (card3) = dict_read{dict_ptr=Hand0}(3)
        hand_cards[3] = card3
        let (card4) = dict_read{dict_ptr=Hand0}(4)
        hand_cards[4] = card4

        return(MAX_HAND_CARDS,hand_cards)
    else:
        let (local Hand1_start) = default_dict_new(default_value=MAX_HAND_CARDS)

        let (Hand1: DictAccess*) = Board.felt_to_dict(current_board, Hand1_start, HAND1_POSITION, DRAFT_ID_SIZE, 0, MAX_HAND_CARDS)

        let (hand_cards : felt*) = alloc()
        let (card0) = dict_read{dict_ptr=Hand1}(0)
        hand_cards[0] = card0
        let (card1) = dict_read{dict_ptr=Hand1}(1)
        hand_cards[1] = card1
        let (card2) = dict_read{dict_ptr=Hand1}(2)
        hand_cards[2] = card2
        let (card3) = dict_read{dict_ptr=Hand1}(3)
        hand_cards[3] = card3
        let (card4) = dict_read{dict_ptr=Hand1}(4)
        hand_cards[4] = card4

        return(MAX_HAND_CARDS,hand_cards)
    end
end

@view
func get_player_board{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_player: felt)->(board_cards_len: felt,board_cards: felt*):
    alloc_locals
    
    let(current_board) = board.read()

    if _player == 0:
        let (local Board0_start) = default_dict_new(default_value=MAX_BOARD_CARDS)

        let (Board0: DictAccess*) = Board.felt_to_dict(current_board, Board0_start, BOARD0_POSITION, CARD_ID_SIZE, 0, MAX_BOARD_CARDS)

        let (board_cards : felt*) = alloc()
        let (card0) = dict_read{dict_ptr=Board0}(0)
        board_cards[0] = card0
        let (card1) = dict_read{dict_ptr=Board0}(1)
        board_cards[1] = card1
        let (card2) = dict_read{dict_ptr=Board0}(2)
        board_cards[2] = card2
        let (card3) = dict_read{dict_ptr=Board0}(3)
        board_cards[3] = card3
        let (card4) = dict_read{dict_ptr=Board0}(4)
        board_cards[4] = card4

        return(MAX_BOARD_CARDS,board_cards)
    else:
        let (local Board1_start) = default_dict_new(default_value=MAX_BOARD_CARDS)

        let (Board1: DictAccess*) = Board.felt_to_dict(current_board, Board1_start, BOARD1_POSITION, CARD_ID_SIZE, 0, MAX_BOARD_CARDS)

        let (board_cards : felt*) = alloc()
        let (card0) = dict_read{dict_ptr=Board1}(0)
        board_cards[0] = card0
        let (card1) = dict_read{dict_ptr=Board1}(1)
        board_cards[1] = card1
        let (card2) = dict_read{dict_ptr=Board1}(2)
        board_cards[2] = card2
        let (card3) = dict_read{dict_ptr=Board1}(3)
        board_cards[3] = card3
        let (card4) = dict_read{dict_ptr=Board1}(4)
        board_cards[4] = card4

        return(MAX_BOARD_CARDS,board_cards)
    end
end

@view
func get_current_player{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}()->(current_player: felt):
    let (current_turn) = get_current_turn()
    let (_,rem) = unsigned_div_rem(current_turn,2)
    if rem == 0:
        return(1)
    else:
        return(0)
    end
end

#One can use this + get_current_player to get the mana amount
@view
func get_current_turn{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}()->(current_turn: felt):
    alloc_locals
    let (current_board) = board.read()
    let (turn_counter: felt) = bits_manipulation.actual_get_element_at(
        input=current_board,
        at=TURN_COUNTER_POSITION,
        number_of_bits=TURN_COUNTER_SIZE
    )
    return(turn_counter)
end

@view
func get_full_board{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}()->(
        hand0_cards_len: felt,
        hand0_cards: felt*,
        hand1_cards_len: felt,
        hand1_cards: felt*,
        board0_cards_len: felt,
        board0_cards: felt*,
        board1_cards_len: felt,
        board1_cards: felt*,
        damage0_len: felt,
        damage0: felt*,
        damage1_len: felt,
        damage1: felt*
    ):
    alloc_locals
    let (current_board) = board.read()

    let (local Hand0_start) = default_dict_new(default_value=MAX_HAND_CARDS)
    let (local Hand1_start) = default_dict_new(default_value=MAX_HAND_CARDS)
    let (local Board0_start) = default_dict_new(default_value=MAX_BOARD_CARDS)
    let (local Board1_start) = default_dict_new(default_value=MAX_BOARD_CARDS)
    let (local Damage0_start) = default_dict_new(default_value=0)
    let (local Damage1_start) = default_dict_new(default_value=0)

    let(
        Hand0: DictAccess*,
        Hand1: DictAccess*,
        Board0: DictAccess*,
        Board1: DictAccess*,
        Damage0: DictAccess*,
        Damage1: DictAccess*,
        Current_Turn: felt
    ) = Board.board_to_dicts(
        current_board,
        Hand0_start,
        Hand1_start,
        Board0_start,
        Board1_start,
        Damage0_start,
        Damage1_start
    )

    let (hand0_cards : felt*) = alloc()
    let (hand1_cards : felt*) = alloc()
    let (board0_cards : felt*) = alloc()
    let (board1_cards : felt*) = alloc()
    let (damage0 : felt*) = alloc()
    let (damage1 : felt*) = alloc()

    #Set hand0 arr
    let (card0) = dict_read{dict_ptr=Hand0}(0)
    hand0_cards[0] = card0
    let (card1) = dict_read{dict_ptr=Hand0}(1)
    hand0_cards[1] = card1
    let (card2) = dict_read{dict_ptr=Hand0}(2)
    hand0_cards[2] = card2
    let (card3) = dict_read{dict_ptr=Hand0}(3)
    hand0_cards[3] = card3
    let (card4) = dict_read{dict_ptr=Hand0}(4)
    hand0_cards[4] = card4

    #Set hand1 arr
    let (card0) = dict_read{dict_ptr=Hand1}(0)
    hand1_cards[0] = card0
    let (card1) = dict_read{dict_ptr=Hand1}(1)
    hand1_cards[1] = card1
    let (card2) = dict_read{dict_ptr=Hand1}(2)
    hand1_cards[2] = card2
    let (card3) = dict_read{dict_ptr=Hand1}(3)
    hand1_cards[3] = card3
    let (card4) = dict_read{dict_ptr=Hand1}(4)
    hand1_cards[4] = card4

    #Set board0 arr
    let (card0) = dict_read{dict_ptr=Board0}(0)
    board0_cards[0] = card0
    let (card1) = dict_read{dict_ptr=Board0}(1)
    board0_cards[1] = card1
    let (card2) = dict_read{dict_ptr=Board0}(2)
    board0_cards[2] = card2
    let (card3) = dict_read{dict_ptr=Board0}(3)
    board0_cards[3] = card3
    let (card4) = dict_read{dict_ptr=Board0}(4)
    board0_cards[4] = card4

    #Set board1 arr
    let (card0) = dict_read{dict_ptr=Board1}(0)
    board1_cards[0] = card0
    let (card1) = dict_read{dict_ptr=Board1}(1)
    board1_cards[1] = card1
    let (card2) = dict_read{dict_ptr=Board1}(2)
    board1_cards[2] = card2
    let (card3) = dict_read{dict_ptr=Board1}(3)
    board1_cards[3] = card3
    let (card4) = dict_read{dict_ptr=Board1}(4)
    board1_cards[4] = card4

    #Set damage0 arr
    let (card0) = dict_read{dict_ptr=Damage0}(0)
    damage0[0] = card0
    let (card1) = dict_read{dict_ptr=Damage0}(1)
    damage0[1] = card1
    let (card2) = dict_read{dict_ptr=Damage0}(2)
    damage0[2] = card2
    let (card3) = dict_read{dict_ptr=Damage0}(3)
    damage0[3] = card3
    let (card4) = dict_read{dict_ptr=Damage0}(4)
    damage0[4] = card4

    #Set damage1 arr
    let (card0) = dict_read{dict_ptr=Damage1}(0)
    damage1[0] = card0
    let (card1) = dict_read{dict_ptr=Damage1}(1)
    damage1[1] = card1
    let (card2) = dict_read{dict_ptr=Damage1}(2)
    damage1[2] = card2
    let (card3) = dict_read{dict_ptr=Damage1}(3)
    damage1[3] = card3
    let (card4) = dict_read{dict_ptr=Damage1}(4)
    damage1[4] = card4

    return(MAX_HAND_CARDS,hand0_cards,MAX_HAND_CARDS,hand1_cards,MAX_BOARD_CARDS,board0_cards,MAX_BOARD_CARDS,board1_cards,MAX_BOARD_CARDS+1,damage0,MAX_BOARD_CARDS+1,damage1)

end

############################
#         Externals        #
############################

#
#Lobby
#

@external
func join_lobby{
    syscall_ptr : felt*,  
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}() -> (player_index: felt):
    
    let (caller_address) = get_caller_address()
    let (player_0) = players.read(0)

    if player_0 != 0 :
        let (player_1) = players.read(1)
        if player_1 != 0:
            return(666)# Lobby full
        else:
            #Join as player 1
            players.write(1,caller_address)
            return(1)
        end
    end
    #Join as player 0
    players.write(0,caller_address)
    return(0)
end    

#
#Draft
#

@external
func get_card_draft{
    syscall_ptr : felt*, 
    bitwise_ptr : BitwiseBuiltin*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}() -> (card_draft: felt):
    alloc_locals
    #Make sure Lobby is full
    let (local player_1) = players.read(1)
    if player_1 == 0 :
        assert 1 = 0
    end

    #Get caller
    let (caller_address) = get_caller_address()
    let (player_0) = players.read(0)
    let (player_1) = players.read(1)

    if player_0 == caller_address :
        #get random number
        let (card_draft) = Random.get_random_number()
        #get current dragt number
        let (len) = draft_player0_selection_len.read()
        #Write public key + random number 
        draft_player0_selection.write(len, Card_Pick(card_draft,0))
        return(card_draft)
    else:
        if player_1 == caller_address:
            #get random number
            let (card_draft) = Random.get_random_number()
            #get current dragt number
            let (len) = draft_player1_selection_len.read()
            #Write public key + random number 
            draft_player1_selection.write(len, Card_Pick(card_draft,0))
            return(card_draft)
        else:
            assert 1 = 2
            return(0)
        end    
    end
end

@external
func select_card{
    syscall_ptr : felt*, 
    bitwise_ptr : BitwiseBuiltin*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(
    _card_index: felt) -> (new_draft: felt):
    alloc_locals

    let (is_index_valid) = is_le_felt(_card_index,2)
    assert is_index_valid = 1

    #Get caller
    let (caller_address) = get_caller_address()
    let (player_0) = players.read(0)
    let (player_1) = players.read(1)

    if player_0 == caller_address :

        let (local len) = draft_player0_selection_len.read()

        if len == DRAFT_LENGTH:
            assert 1 = 2
        end

        let(current_random_number) = draft_player0_selection.read(len)

        draft_player0_selection.write(len, Card_Pick(current_random_number.random_number,_card_index))

        draft_player0_selection_len.write(len+1)

        #If we hit draft end, there is no need to draw another draft    
        if len + 1 == DRAFT_LENGTH:
            return(0)
        end

        let (new_random_number) = get_card_draft()
        draft_player0_selection.write(len+1, Card_Pick(new_random_number,0))

        return(new_random_number)
    else:
        if player_1 == caller_address:
            let (local len) = draft_player1_selection_len.read()

            if len == DRAFT_LENGTH:
                assert 1 = 2
            end

            let(current_random_number) = draft_player1_selection.read(len)

            draft_player1_selection.write(len, Card_Pick(current_random_number.random_number,_card_index))

            draft_player1_selection_len.write(len+1)
            
            #If we hit draft end, there is no need to draw another draft
            if len + 1 == DRAFT_LENGTH:
                return(0)
            end

            let (new_random_number) = get_card_draft()
            draft_player1_selection.write(len+1, Card_Pick(new_random_number,0))

            return(new_random_number)
        else:
            assert 1 = 2
            return(0)
        end     
    end
    
end

#
#Game
#

@external
func initial_draw{
    syscall_ptr : felt*, 
    bitwise_ptr : BitwiseBuiltin*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}()->(draw1: felt,draw2: felt,draw3: felt):
    alloc_locals

    #CHECK THAT DRAFT HAS ENDED
    assert_is_draft_complete()

    let (caller_address) = get_caller_address()
    let (player_0) = players.read(0)
    let (player_1) = players.read(1)

    if player_0 == caller_address:
        let (local draft_index_1) = draw_card(0)
        let (local draft_index_2) = draw_card(0)
        let (local draft_index_3) = draw_card(0)
        return(draft_index_1,draft_index_2,draft_index_3)
    else:
        if player_1 == caller_address:
            let (local draft_index_1) = draw_card(1)
            let (local draft_index_2) = draw_card(1)
            let (local draft_index_3) = draw_card(1)
            return(draft_index_1,draft_index_2,draft_index_3)
        else:
            assert 1 = 4
            return(0,0,0)
        end    
    end
end

@external
func post_action{
    syscall_ptr : felt*, 
    bitwise_ptr : BitwiseBuiltin*, 
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(
    _actions_len: felt,
    _actions:felt*
    )->(testRes: felt):
    alloc_locals

    #CHECK THAT DRAFT HAS ENDED
    assert_is_draft_complete()

    #GET CURRENT GAME STATE
    let (current_board: felt) = board.read()

    let (local Hand0_start) = default_dict_new(default_value=MAX_HAND_CARDS)
    let (local Hand1_start) = default_dict_new(default_value=MAX_HAND_CARDS)
    let (local Board0_start) = default_dict_new(default_value=MAX_BOARD_CARDS)
    let (local Board1_start) = default_dict_new(default_value=MAX_BOARD_CARDS)
    let (local Damage0_start) = default_dict_new(default_value=0)
    let (local Damage1_start) = default_dict_new(default_value=0)

    let Hand0_Empty = Hand0_start
    let Hand1_Empty = Hand1_start
    let Board0_Empty = Board0_start
    let Board1_Empty = Board1_start
    let Damage0_Empty = Damage0_start
    let Damage1_Empty = Damage1_start

    #TRANSFORM BOARD TO DICTS (is maybe more compute friendly then felt pointers?)
    let(
        Hand0: DictAccess*,
        Hand1: DictAccess*,
        Board0: DictAccess*,
        Board1: DictAccess*,
        Damage0: DictAccess*,
        Damage1: DictAccess*,
        Current_Turn: felt
    ) = Board.board_to_dicts(
        current_board,
        Hand0_Empty,
        Hand1_Empty,
        Board0_Empty,
        Board1_Empty,
        Damage0_Empty,
        Damage1_Empty
    )

    #DETERMINE CURRENT PLAYER
    let (local current_player) = get_current_player()

    #CHECK THAT CURRENT PLAYER IS CALLER_ADDRESS
    let (caller_address) = get_caller_address()
    let (current_player_address) = players.read(current_player)
    assert caller_address = current_player_address

    #GET MANA 
    let (mana) = get_mana_balance(Current_Turn) # ...atm MANA = current_turn + 5, for testing purposed

    #VERIFY GAME ACTIONS AND ADD THEM TO GAME STATE
    let(
        Hand0_End,
        Hand1_End,
        Board0_End,
        Board1_End,
        Damage0_End,
        Damage1_End
    ) = compute_actions(
        _actions_len,
        _actions,
        Hand0,
        Hand1,
        Board0,
        Board1,
        Damage0,
        Damage1,
        current_player,
        Current_Turn,
        mana
    )  

    #SQUASH DICTS
    let (_,squashed_hand0) = default_dict_finalize(Hand0_start, Hand0_End, DRAFT_LENGTH)
    let (_,squashed_hand1) = default_dict_finalize(Hand1_start, Hand1_End, DRAFT_LENGTH)

    let (_,squashed_board0) = default_dict_finalize(Board0_start, Board0_End, DRAFT_LENGTH)
    let (_,squashed_board1) = default_dict_finalize(Board1_start, Board1_End, DRAFT_LENGTH)

    let (_,squashed_damage0) = default_dict_finalize(Damage0_start, Damage0_End, 0)
    let (_,squashed_damage1) = default_dict_finalize(Damage1_start, Damage1_End, 0)

    let (new_board) = board.read()
    #WRITE RESULTS TO GAME STATE
    let (final_board: felt
    ) = Board.dicts_to_board(
        new_board,
        squashed_hand0,
        squashed_hand1,
        squashed_board0,
        squashed_board1,
        squashed_damage0,
        squashed_damage1,
        Current_Turn
    )

    board.write(final_board)

    return(0)
end 

#NOT EXTERNAL, but it's to essential for the game logic to be drowned down there with the internal plebs
func compute_actions{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(
        _actions_len : felt,
        _actions : felt*,
        _Hand0: DictAccess*,
        _Hand1: DictAccess*,
        _Board0: DictAccess*,
        _Board1: DictAccess*,
        _Damage0: DictAccess*,
        _Damage1: DictAccess*,
        _current_player: felt,
        _current_turn: felt,
        _mana_balance: felt
    )->(
        Hand0_End: DictAccess*,
        Hand1_End: DictAccess*,
        Board0_End: DictAccess*,
        Board1_End: DictAccess*,
        Damage0_End: DictAccess*,
        Damage1_End: DictAccess*
    ):
    alloc_locals

    local player_hand : DictAccess*
    local player_board : DictAccess*
    local player_damage : DictAccess*
    local opponent_board : DictAccess*
    local opponent_hand : DictAccess*
    local opponent_damage : DictAccess*

    local final_opponent_board : DictAccess*
    local final_opponent_damage : DictAccess*
    local final_player_damage : DictAccess*
    local final_player_board : DictAccess*

    if _current_player == 0:
        player_hand = _Hand0
        player_board = _Board0
        player_damage = _Damage0
        opponent_board = _Board1
        opponent_hand = _Hand1
        opponent_damage = _Damage1
    else:
        player_hand = _Hand1
        player_board = _Board1
        player_damage = _Damage1
        opponent_board = _Board0
        opponent_hand = _Hand0
        opponent_damage = _Damage0
    end

    if _actions_len == 0:
        #DRAW CARD FOR THE OTHER PLAYER
        if _current_player == 0 :
            let (draft_index) = draw_card(1)
            let (new_hand_dict) = add_card_to_hand(draft_index,_Hand1,0)
	    return(
                _Hand0,
                new_hand_dict,
                _Board0,
                _Board1,
                _Damage0,
                _Damage1
            )
        else:
            let (draft_index) = draw_card(0)
       	    let (new_hand_dict) = add_card_to_hand(draft_index,_Hand0,0)     
	    return(
                new_hand_dict,
                _Hand1,
                _Board0,
                _Board1,
                _Damage0,
                _Damage1
            )
        end
    end

    #Card placement
    #[1] hand index
    #[2] placement position
    #[3] signature_1
    #[4] signature_2
    if _actions[0] == Placement_action:

        #Check that the card is currently in hand
        let (deck_index) = dict_read{dict_ptr=player_hand}(_actions[1])

        if deck_index == DRAFT_LENGTH:
            assert 0 = 1
        end 

        #Reveil Card that was drawn and selected during draft
        let (card_id) = assert_proof_card(Signature(_actions[3], _actions[4]), deck_index, _current_player)
        
        # check mana cost
        let (mana_cost) = get_mana_cost(card_id)
        assert_le(mana_cost,_mana_balance)

        #Check that board isn't full and then add card to board
        let (changed_player_board) = add_card_to_board(card_id,_actions[2],player_board)  

        #Remove Card from hand and shift other cards if needed
        let (changed_hand) = remove_card_from_hand(_actions[1],player_hand)

        if _current_player == 0:
            let (
                Hand0_End,
                Hand1_End,
                Board0_End,
                Board1_End,
                Damage0_End,
                Damage1_End
            ) = compute_actions(
                _actions_len-5,
                _actions+5,
                changed_hand,
                opponent_hand,
                changed_player_board,
                opponent_board,
                player_damage,
                opponent_damage,
                _current_player,
                _current_turn,
                _mana_balance - mana_cost
            )

            return(
                Hand0_End,
                Hand1_End,
                Board0_End,
                Board1_End,
                Damage0_End,
                Damage1_End
            )
        else:
            let (
                Hand0_End,
                Hand1_End,
                Board0_End,
                Board1_End,
                Damage0_End,
                Damage1_End
            ) = compute_actions(
                _actions_len-5,
                _actions+5,
                opponent_hand,
                changed_hand,
                opponent_board,
                changed_player_board,
                opponent_damage,
                player_damage,
                _current_player,
                _current_turn,
                _mana_balance - mana_cost
            )

            return(
                Hand0_End,
                Hand1_End,
                Board0_End,
                Board1_End,
                Damage0_End,
                Damage1_End
            )
        end    
    else:
        tempvar ecdsa_ptr = ecdsa_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar syscall_ptr = syscall_ptr
        tempvar bitwise_ptr = bitwise_ptr
    end

    #Card attack
    #[1] attacking card position (0-4)
    #[2] target position (0-5) can be card or hero
    if _actions[0] == Attack_action:
        #Get Card_id from provided board position
        let (card_id) = dict_read{dict_ptr=player_board}(_actions[1])

        #Check that attacker is actually a card
        if card_id == DRAFT_LENGTH:
            assert 1 = 2
        end 

        #Check that attacker hasn't already attacked this turn
        #TODO

        #Get card stats
        let (card: Card) = cards.read(card_id)
        #If target is hero
        if _actions[2] == MAX_BOARD_CARDS:
            #Subtract hero health according to card attack
            let (current_damage_on_hero) = dict_read{dict_ptr=player_damage}(_actions[2])

            tempvar new_hero_hp = (HERO_HP - current_damage_on_hero) - card.attack
            let (is_hero_dead) = is_le_felt(new_hero_hp,0)
            if is_hero_dead == 1:
                #END GAME
		#TODO The game should be ended here and a player should be crowned the victor
                return(
                    _Hand0,
                    _Hand1,
                    _Board0,
                    _Board1,
                    _Damage0,
                    _Damage1
                )
            end
            #Save that card has attacked this turn
            dict_write{dict_ptr=opponent_damage}(5,new_hero_hp)

            let (Hand0_End,Hand1_End,Board0_End,Board1_End,Damage0_End,Damage1_End) = compute_actions(
                _actions_len-3,
                _actions+3,
                opponent_hand,
                player_hand,
                opponent_board,
                player_board,
                opponent_damage,
                player_damage,
                _current_player,
                _current_turn,
                _mana_balance
            )
        
            return(
                Hand0_End,
                Hand1_End,
                Board0_End,
                Board1_End,
                Damage0_End,
                Damage1_End
            )
        else:
            #Get Card_id from provided board position
            let (target_card_id) = dict_read{dict_ptr=opponent_board}(_actions[2]) 

            #Check that attacked position actually holds a card
            if card_id == DRAFT_LENGTH:
                assert 1 = 2
            end 
            #Get Target position damge
            let (target_damage) = dict_read{dict_ptr=opponent_damage}(_actions[2]) 

            #Get Target card
            let (target_card: Card) = cards.read(target_card_id)
            #Calc new target card hp
            tempvar new_card_hp = target_card.health - (target_damage + card.attack)
            #Check if target card is destroyed
            let (is_card_destoyed) = is_le_felt(new_card_hp,0)

            if is_card_destoyed == 1:
                #Remove card from board
                dict_write{dict_ptr=opponent_board}(_actions[2],DRAFT_LENGTH)
                final_opponent_board = opponent_board
                #Reset Damage 
                dict_write{dict_ptr=opponent_damage}(_actions[2],0)
                final_opponent_damage = opponent_damage
            else:
                #Add attack to damge dict
                dict_write{dict_ptr=opponent_damage}(_actions[2],target_damage + card.attack)
                final_opponent_damage = opponent_damage
            end
            
            let (attacker_damage) = dict_read{dict_ptr=player_damage}(_actions[1]) 

            #Remove hp from attacking card 
            tempvar new_attacking_card_hp = card.health - (attacker_damage + target_card.attack)
            #Check if target card is destroyed
            let (is_attacking_card_destoyed) = is_le_felt(new_attacking_card_hp,0)
            
            if is_attacking_card_destoyed == 1:
                #Remove card from board
                dict_write{dict_ptr=player_board}(_actions[1],DRAFT_LENGTH)
                final_player_board = player_board
                #Reset Damage 
                dict_write{dict_ptr=player_damage}(_actions[1],0)
                final_player_damage = player_damage
            else:
                #Add attack to damage dict
                dict_write{dict_ptr=player_damage}(_actions[1],attacker_damage + target_card.attack)
                final_player_damage = player_damage
            end
            
            let (Hand0_End,Hand1_End,Board0_End,Board1_End,Damage0_End,Damage1_End) = compute_actions(
                _actions_len-3,
                _actions+3,
                opponent_hand,
                player_hand,
                final_opponent_board,
                final_player_board,
                final_opponent_damage,
                final_player_damage,
                _current_player,
                _current_turn,
                _mana_balance
            )
        
            return(
                Hand0_End,
                Hand1_End,
                Board0_End,
                Board1_End,
                Damage0_End,
                Damage1_End
            )
        end
    else:
        return(
            _Hand0,
            _Hand1,
            _Board0,
            _Board1,
            _Damage0,
            _Damage1
        )
    end 
end

#
#Admin
#

#Should only be callable once, and then never again
@external
func set_cards{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(
    _counter: felt, 
    _cards_len: felt, 
    _cards: Card*):
    if _counter == DRAFT_LENGTH-1 :
        return()
    end
    cards.write(_counter,_cards[0])
    set_cards(_counter+1,_cards_len,_cards+1)
    return()
end

############################
#         Internals        #
############################   

func assert_proof_card{
    syscall_ptr : felt*, 
    bitwise_ptr : BitwiseBuiltin*, 
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_signature: Signature, _deck_index: felt, _current_player: felt) -> (proven_card: felt):
    alloc_locals

    local pick : Card_Pick

    #Get current players public key
    let (account_public_key) = players.read(_current_player)   
    #Last minute change, players should join lobby with this key and not the account address
    let (og_public_key) = IAccount.get_public_key(account_public_key)

    #Get the card from the Deck
    if _current_player == 0:
        let (pick1: Card_Pick) = draft_player0_selection.read(_deck_index)
        assert pick = pick1

        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr 
    else:
        let (pick2: Card_Pick) = draft_player1_selection.read(_deck_index)
        assert pick = pick2

        tempvar syscall_ptr = syscall_ptr
        tempvar range_check_ptr = range_check_ptr
        tempvar pedersen_ptr = pedersen_ptr
    end
    
    #Hash random number
    let (amount_hash) = hash2{hash_ptr=pedersen_ptr}(pick.random_number, 0)
    #Proof that the provided signature was actually generated using that deck indexes card pick
    verify_ecdsa_signature(
        amount_hash,
        og_public_key,
        signature_r=_signature.one,
        signature_s=_signature.two,
    )

    #Extract draft from signature
    let (draft) = get_draft_from_sig(_signature.one)

    #Get Card ID from picked index
    local proven_card_pick : felt
    if pick.index == 0:
        let (final,_) = unsigned_div_rem(draft,10000)
        proven_card_pick = final
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr = syscall_ptr
    else:
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr = syscall_ptr
    end

    if pick.index == 1:
        let (left_side,_) = unsigned_div_rem(draft,100)
        let (smaller_left_side,_) = unsigned_div_rem(draft,100)
        tempvar final = draft - (smaller_left_side * 100)
        proven_card_pick = final
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr = syscall_ptr
    else:
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr = syscall_ptr
    end

    if pick.index == 2:
        let (left_side,_) = unsigned_div_rem(draft,100)
        tempvar final = draft - left_side * 100
        proven_card_pick = final
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr = syscall_ptr
    else:
        tempvar range_check_ptr = range_check_ptr
        tempvar syscall_ptr = syscall_ptr
    end    

    # The received random number is in the range of 0-99. 
    # As we only have 20 cards, we need to normalize the random number to that range
    let (normalized_pick) = normalize_pick(proven_card_pick,NUMBER_OF_UNIQUE_CARDS)
        
    return(normalized_pick)
end

func normalize_pick{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_proven_card_pick: felt, _max_val : felt) -> (normalize_pick: felt):
    let (normalize_pick,_) = unsigned_div_rem((_proven_card_pick - 0)*_max_val,99-0)
    return(normalize_pick)
end   

func get_mana_balance{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(turn_counter: felt)->(mana_balance: felt):

    return(turn_counter+5) #We increase the initial mana amount for testing purposes
end     

func get_mana_cost{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(
    card_id: felt)->(mana_cost: felt):

    let(card: Card) = cards.read(card_id)

    return(Card.cost)
end

func remove_card_from_hand{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_hand_index: felt, _player_hand: DictAccess*) -> (changed_hand: DictAccess*):
    alloc_locals

    let (local next_card : felt) = dict_read{dict_ptr=_player_hand}(key=_hand_index+1)

    if next_card == DRAFT_LENGTH :
        #remove last card
        dict_write{dict_ptr=_player_hand}(_hand_index,0)
        return(_player_hand)
    end    

    #shift left card to the right
    let (local shifted_player_hand) = shift_cards_left(_player_hand,_hand_index)

    return(shifted_player_hand)
end

func shift_cards_left{range_check_ptr}(_player_hand: DictAccess*,_hand_index: felt) -> (shifted_player_hand: DictAccess*):
    alloc_locals

    let (local next_card : felt) = dict_read{dict_ptr=_player_hand}(key=_hand_index+1)

    if next_card == DRAFT_LENGTH :
        #remove last card
        dict_write{dict_ptr=_player_hand}(_hand_index,DRAFT_LENGTH)
        return(_player_hand)
    end    

    #shift left card to the right
    let (local card : felt) = dict_read{dict_ptr=_player_hand}(key=_hand_index+1)
    dict_write{dict_ptr=_player_hand}(_hand_index,card)

    let (shifted_player_hand) = shift_cards_left(_player_hand,_hand_index+1)

    return(shifted_player_hand)
end

func add_card_to_board{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_card_id: felt, _placement_position: felt,_board_dict: DictAccess*
    )->(changed_board_dict: DictAccess*):
    alloc_locals
    #Get id at position
    let (local card_id) = dict_read{dict_ptr=_board_dict}(key=_placement_position)
    
    #Check that position is empty
    if card_id != DRAFT_LENGTH:
        assert 1 = 2
    end 

    #write card to position
    dict_write{dict_ptr=_board_dict}(_placement_position,_card_id)
    
    return(_board_dict)
end

func add_card_to_hand{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_draft_index: felt,_hand_dict: DictAccess*, _hand_counter: felt
    )->(changed_hand_dict: DictAccess*):
    alloc_locals
    #TODO: CHECK THAT HAND SIZE IS NOT FULL, and act accordingly

    local changed_hand_dict : DictAccess*

    let (draft_index) = dict_read{dict_ptr=_hand_dict}(key=_hand_counter)

    #If spot is empty, we write to hand
    if draft_index == DRAFT_LENGTH:
        changed_hand_dict = _hand_dict
        dict_write{dict_ptr=changed_hand_dict}(_hand_counter,_draft_index)
        return(changed_hand_dict)
    end

    let (final_hand) = add_card_to_hand(_draft_index, _hand_dict, _hand_counter+1)
    return(final_hand)
end

func draw_card{
    syscall_ptr : felt*,
    bitwise_ptr : BitwiseBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_player: felt)->(drawn_card_id: felt):
    alloc_locals
    let (local random_number) = Random.get_random_number()
    local deck_position : felt
    local hand_position : felt

    if _player == 0:
        deck_position = DECK0_POSITION
        hand_position = HAND0_POSITION
    else:
        deck_position = DECK1_POSITION
        hand_position = HAND1_POSITION
    end

    #Get player deck
    let (current_board) = board.read()

    #Get deck length
    let (deck_len) = bits_manipulation.actual_get_element_at(
        input=current_board,
        at=deck_position + (DRAFT_LENGTH * DECK_INDEX_SIZE),
        number_of_bits = DECK_LEN_SIZE
    )
    
    #TODO:
    #Handle the situation if the deck is empty
    #Handle the situation if the hand is full

    #Check that deck length > 0
    assert_not_zero(deck_len) 

    #take last two digits from random_number
    let (left_side,_) = unsigned_div_rem(random_number,100)
    tempvar last_two_digits = random_number - left_side * 100

    #The last two digits are in a range of 0-99
    #We normalize down to the range of the deck size 0-deck_len
    #Determine deck index of newly drawn card
    let (deck_index) = normalize_pick(last_two_digits,deck_len)

    #Set new Deck length
    let (changed_board) = bits_manipulation.actual_set_element_at(current_board, deck_position + (DRAFT_LENGTH * DECK_INDEX_SIZE), DECK_LEN_SIZE, deck_len-1)

    #TODO: check if dicts are actually more efficient then using felt pointers
    #Transform deck_felt to dict
    let (local start_deck_dict) = default_dict_new(default_value=DRAFT_LENGTH)
    local empty_dict: DictAccess* = start_deck_dict 
    let (deck_dict: DictAccess*) = Board.deck_to_dict(empty_dict,changed_board,deck_len,deck_len,deck_position) 
    let (local start_hand_dict) = default_dict_new(default_value=DRAFT_LENGTH)
    local empty_dict: DictAccess* = start_hand_dict
    let (hand_dict: DictAccess*) = Board.felt_to_dict(changed_board,empty_dict,hand_position, DRAFT_ID_SIZE, 0, MAX_HAND_CARDS-1)       

    #Get draft index
    let (draft_index) = dict_read{dict_ptr=deck_dict}(key=deck_index)

    #Remove Card from deck
    let (shifted_deck_dict: DictAccess*)= shift_cards_left(deck_dict,deck_index)
    #Add new Card to hand
    let (new_hand_dict: DictAccess*) = add_card_to_hand(draft_index,hand_dict,0)

    #Squash dicts (Is it fine to squash and then still read from them?)
    default_dict_finalize(start_deck_dict, shifted_deck_dict, DRAFT_LENGTH)
    default_dict_finalize(start_hand_dict, new_hand_dict, DRAFT_LENGTH)

    #Transform hand and deck changes to board felt
    let (new_board) = Board.dict_to_felt(changed_board, shifted_deck_dict, deck_position, DECK_INDEX_SIZE, 0, deck_len)    
    let (final_board) = Board.dict_to_felt(new_board, new_hand_dict, hand_position, DRAFT_ID_SIZE, 0, MAX_HAND_CARDS-1)  

    #Save new deck
    #ofc we shouldn't be writing to storage here, but I don't have time to change this
    board.write(final_board)

    return(draft_index)
 
end

func assert_is_draft_complete{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}():
    alloc_locals
    let (len0) = draft_player1_selection_len.read()
    if len0 != DRAFT_LENGTH:
        assert 1 = 2
    end
    let (len1) = draft_player0_selection_len.read()
    if len1 != DRAFT_LENGTH:
        assert 1 = 2
    end
    return()
end

%lang starknet

from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.dict import (dict_write, dict_read)
from starkware.cairo.common.default_dict import default_dict_new

from starkware.cairo.common.cairo_builtins import (BitwiseBuiltin, HashBuiltin)
from lib.starknet_felt_packing_git.contracts.bits_manipulation import external as bits_manipulation
from src.lib.game_settings import (
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

namespace Board:

    func board_to_dicts{
        syscall_ptr : felt*, 
        bitwise_ptr : BitwiseBuiltin*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr}(
        _board: felt,
        _Hand0_Empty: DictAccess*,
        _Hand1_Empty: DictAccess*,
        _Board0_Empty: DictAccess*,
        _Board1_Empty: DictAccess*,
        _Damage0_Empty: DictAccess*,
        _Damage1_Empty: DictAccess*)->(Hand0: DictAccess*,Hand1: DictAccess*,Board0: DictAccess*,Board1: DictAccess*,Damage0: DictAccess*,Damage1: DictAccess*,Turn_Counter: felt):
        alloc_locals

        #Get Hand of player0
        let (local Hand0: DictAccess*) = felt_to_dict(_board, _Hand0_Empty, HAND0_POSITION, DRAFT_ID_SIZE, 0, MAX_HAND_CARDS)

        #Get Hand of player1
        let (local Hand1: DictAccess*) = felt_to_dict(_board, _Hand1_Empty, HAND1_POSITION, DRAFT_ID_SIZE, 0, MAX_HAND_CARDS)

        #Get Board of player0
        let (local Board0: DictAccess*) = felt_to_dict(_board, _Board0_Empty, BOARD0_POSITION, CARD_ID_SIZE, 0, MAX_BOARD_CARDS)

        #Get Board of player1
        let (local Board1: DictAccess*) = felt_to_dict(_board, _Board1_Empty, BOARD1_POSITION, CARD_ID_SIZE, 0, MAX_BOARD_CARDS)

        #Get Damage of player0
        let (local Damage0: DictAccess*) = felt_to_dict(_board, _Damage0_Empty, DAMAGE0_POSITION, DAMAGE_AMOUNT_SIZE, 0, MAX_BOARD_CARDS+1) # + HERO HP

        #Get Damage of player1
        let (local Damage1: DictAccess*) = felt_to_dict(_board, _Damage1_Empty, DAMAGE1_POSITION, DAMAGE_AMOUNT_SIZE, 0, MAX_BOARD_CARDS+1)

        #Also get the turn counter
        let (Turn_Counter: felt) = bits_manipulation.actual_get_element_at(
            input=_board,
            at=TURN_COUNTER_POSITION,
            number_of_bits=TURN_COUNTER_SIZE
        )

        return(Hand0,Hand1,Board0,Board1,Damage0,Damage1,Turn_Counter)
    end

    func dicts_to_board{
        syscall_ptr : felt*, 
        bitwise_ptr : BitwiseBuiltin*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr}(current_board: felt,squashed_hand0: DictAccess*,squashed_hand1: DictAccess*,squashed_board0: DictAccess*,squashed_board1: DictAccess*,squashed_damage0: DictAccess*,squashed_damage1: DictAccess*,_current_turn: felt) -> (final_board: felt):
        alloc_locals

        let (boardV1) = dict_to_felt(current_board, squashed_hand0, HAND0_POSITION, DRAFT_ID_SIZE, 0, MAX_HAND_CARDS-1)

        let (boardV2) = dict_to_felt(boardV1, squashed_hand1, HAND1_POSITION, DRAFT_ID_SIZE, 0, MAX_HAND_CARDS-1)

        let (boardV3) = dict_to_felt(boardV2, squashed_board0, BOARD0_POSITION, CARD_ID_SIZE, 0, MAX_BOARD_CARDS-1)

        let (boardV4) = dict_to_felt(boardV3, squashed_board1, BOARD1_POSITION, CARD_ID_SIZE, 0, MAX_BOARD_CARDS-1)

        let (boardV5) = dict_to_felt(boardV4, squashed_damage0, DAMAGE0_POSITION, DAMAGE_AMOUNT_SIZE, 0, MAX_BOARD_CARDS)

        let (boardV6) = dict_to_felt(boardV5, squashed_damage1, DAMAGE1_POSITION, DAMAGE_AMOUNT_SIZE, 0, MAX_BOARD_CARDS)

        let (final_board) = bits_manipulation.actual_set_element_at(boardV6, TURN_COUNTER_POSITION, TURN_COUNTER_SIZE, _current_turn+1)
        
        return(final_board)
    end

    func deck_to_dict{
        syscall_ptr : felt*, 
        bitwise_ptr : BitwiseBuiltin*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr}(_deck_dict: DictAccess*, _board: felt, _deck_len: felt, _deck_max_size: felt, _deck_position: felt)->(deck_dict: DictAccess*):

        if _deck_len == 0:
            return(_deck_dict)
        end

        let (deck_id: felt) = bits_manipulation.actual_get_element_at(
            input=_board,
            at=_deck_position + ((_deck_max_size - _deck_len)*DECK_INDEX_SIZE),
            number_of_bits=DECK_INDEX_SIZE
        )
        dict_write{dict_ptr=_deck_dict}((_deck_max_size - _deck_len),deck_id)

        let(new_deck_dict) = deck_to_dict(_deck_dict,_board,_deck_len-1,_deck_max_size,_deck_position)

        return(new_deck_dict)
    end

    func dict_to_felt{
        syscall_ptr : felt*, 
        bitwise_ptr : BitwiseBuiltin*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr}(_board: felt, _dict: DictAccess*, _position: felt, _element_size: felt, _index: felt, _index_limit: felt)->(new_board: felt):
        alloc_locals

        if _index==_index_limit:
            return(_board)
        end 

        let (element) = dict_read{dict_ptr=_dict}(key=_index)
        tempvar board_position_to_edit = _position+(_element_size*_index)
        let (new_board) = bits_manipulation.actual_set_element_at(_board, board_position_to_edit, _element_size, element)

        let (final_board) = dict_to_felt(new_board, _dict, _position, _element_size, _index+1, _index_limit)

        return(final_board)
    end

    func felt_to_dict{
        syscall_ptr : felt*, 
        bitwise_ptr : BitwiseBuiltin*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr}(_board: felt, _dict: DictAccess*, _position: felt, _element_size: felt, _index: felt, _index_limit: felt)->(new_dict: DictAccess*):
        alloc_locals

        if _index==_index_limit:
            return(_dict)
        end 

        let (dict_element: felt) = bits_manipulation.actual_get_element_at(
            input=_board,
            at=_position + (_index*_element_size),
            number_of_bits=_element_size
        )

        dict_write{dict_ptr=_dict}(_index,dict_element)

        let(final_dict) = felt_to_dict(_board,_dict,_position,_element_size,_index+1,_index_limit)

        return(final_dict)
    end 

end    
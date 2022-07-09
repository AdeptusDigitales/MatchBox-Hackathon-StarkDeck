%lang starknet

struct Card_Pick:
    member random_number : felt
    member index : felt
end

struct Card:
    member cost : felt
    member attack : felt
    member health : felt
end

@contract_interface
namespace IMain:

    func post_action(_actions_len: felt, _actions: felt*)->(res: felt):
    end

    func select_card(_card_index: felt)->(res: felt):
    end

    func get_card_draft()->(card_draft: felt):
    end

    func get_deck_len(_player: felt)->(deck_len: felt):
    end

    func get_hand(_player: felt)->(hand_cards_len: felt,hand_cards: felt*):
    end

    func get_player_board(_player: felt)->(board_cards_len: felt,board_cards: felt*):
    end

    func join_lobby():
    end

    func get_board()->(board: felt):
    end

    func get_players()->(player0: felt, player1: felt):
    end

    func get_draft(_index: felt, _player: felt)->(card_pick: Card_Pick):
    end

    func initial_draw()->(draw1: felt,draw2: felt,draw3: felt):
    end

    func set_cards(
        _counter: felt,
        _cards_len: felt, 
        _cards: Card*):
    end
end

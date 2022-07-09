%lang starknet

from protostar.asserts import (assert_eq)
from starkware.cairo.common.bitwise import bitwise_and, bitwise_or, bitwise_xor
from starkware.cairo.common.cairo_builtins import (BitwiseBuiltin, HashBuiltin, SignatureBuiltin)
from starkware.cairo.common.math import assert_le, split_felt, unsigned_div_rem, split_int
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import (
    verify_ecdsa_signature,
)
from interfaces.IMain import (IMain, Card_Pick, Card)
from lib.starknet_felt_packing_git.contracts.bits_manipulation import external as bits_manipulation

const evidence_base = 100000000000000000000000000000000000000000000000000000000000000000000000000

@storage_var
func main_contract()->(address: felt):
end

@external
func test_draft{
    syscall_ptr : felt*, 
    bitwise_ptr : BitwiseBuiltin*, 
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}():
    alloc_locals

    local main_address : felt
    # Deploy Main contract
    %{ ids.main_address = deploy_contract("./src/main.cairo").contract_address %}

    local public_key_0 = 1162637274776062843434229637044893256148643831598397603392524411337131005673
    local public_key_1 = 111813453203092678575228394645067365508785178229282836578911214210165801044

    #Player 0 joins the lobby
    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    IMain.join_lobby(main_address)
    %{ stop_prank_callable() %}

    #Player 1 joins the lobby
    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    IMain.join_lobby(main_address)
    %{ stop_prank_callable() %}

    #GET PLAYERS
    #let (player0,player1) = IMain.get_players(main_address) 
    #%{ print("player0: ",ids.player0) %}
    #%{ print("player1: ",ids.player1) %}

    let (board) = IMain.get_board(main_address)
    #%{ print("board: ",ids.board) %}

    set_cards(main_address)
    
    setting_up_draft(public_key_0,public_key_1,main_address)

    draw_initial_cards(main_address,public_key_0,public_key_1)  

    #post_action(main_address,public_key_0,public_key_1)

    let (hand_len: felt,hand0: felt*) = IMain.get_hand(main_address,1)
    
    tempvar card0 = hand0[0]
    tempvar card1 = hand0[1]
    tempvar card2 = hand0[2]
    tempvar card3 = hand0[3]
    tempvar card4 = hand0[4]

    %{ print("hand0: ",ids.card0) %}
    %{ print("hand1: ",ids.card1) %}
    %{ print("hand2: ",ids.card2) %}
    %{ print("hand3: ",ids.card3) %}
    %{ print("hand4: ",ids.card4) %}

    let (board_len: felt,board0: felt*) = IMain.get_player_board(main_address,1)
    
    tempvar card0 = board0[0]
    tempvar card1 = board0[1]
    tempvar card2 = board0[2]
    tempvar card3 = board0[3]
    tempvar card4 = board0[4]

    %{ print("board0: ",ids.card0) %}
    %{ print("board1: ",ids.card1) %}
    %{ print("board2: ",ids.card2) %}
    %{ print("board3: ",ids.card3) %}
    %{ print("board4: ",ids.card4) %}

    return()

end

@external
func setting_up_draft{
    syscall_ptr : felt*, 
    bitwise_ptr : BitwiseBuiltin*, 
    ecdsa_ptr : SignatureBuiltin*,
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(public_key_0: felt,public_key_1: felt, main_address: felt):
    alloc_locals
    ##############
    #  PLAYER 1  #
    ##############

    #Player 0 picks first draft
    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    let (draft_random_number) = IMain.get_card_draft(main_address)
    %{ stop_prank_callable() %}
                     
    tempvar sig_0 = 3593274851548992787257084612043511751214817639696578828668640537276412280294
    tempvar sig_1 = 3439035480383532763945347287788660091091936393912935928327577280281251561650

    #Player 0 makes card selection (index 0)
    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,0)
    %{ stop_prank_callable() %}

    tempvar sig_0 = 288988211912624458357233874342735482685160899947628751053886260154718525087
    tempvar sig_1 = 621004040861774497492117296174370398254232409139528250771606584684085301738

    #Player 0 picks second draft
    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,1)
    %{ stop_prank_callable() %}

    tempvar sig_0 = 1983493237690664383678917941089042327200578790859395265287639178180678433703
    tempvar sig_1 = 2486684321064533073810189852781816080512846373861366267891408697072163859469

    #Player 0 picks third draft
    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,2)
    %{ stop_prank_callable() %}

    tempvar sig_0 = 3520946670207311696452862485752786087080542459149643480505056748727352413151
    tempvar sig_1 = 1869180047908130272678343504614242117300102794495090870621043884084861351017

    #Player 0 picks fourth draft
    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,0)
    %{ stop_prank_callable() %}

    tempvar sig_0 = 2702130143653469664635674333387549321432186687218456371575444532531840316473
    tempvar sig_1 = 2514985270870306118591021321035415198795103157172494183887088015061738886743

    #Player 0 picks fith draft
    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,1)
    %{ stop_prank_callable() %}

    #%{ print("new_random_number: ",ids.new_random_number) %}

    #let (deck_len) = bits_manipulation.actual_get_element_at(
    #    input=new_random_number,
    #    at=15,
    #    number_of_bits=5
    #)
    #%{ print("First Draw: ",ids.deck_len) %}

    ##############
    #  PLAYER 2  #
    ##############

    #Player 1 gets first draft
    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    let (draft_random_number) = IMain.get_card_draft(main_address)
    %{ stop_prank_callable() %}

    tempvar sig_0 = 2238180960614545594660352259605384408008638188242332776115650331761922406142
    tempvar sig_1 = 329062126174762413048706470813244127768580782054982235131945122444758974957

    #Player 1 picks first draft
    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,0)
    %{ stop_prank_callable() %}

    tempvar sig_0 = 2143512662092032338068964608743837735155237936010256365468066160515760996812
    tempvar sig_1 = 1798020751961883533066495744551457859192383776153434573846462401735796683386

    #%{ print("new_random_number: ",ids.new_random_number) %}

    #Player 1 picks second draft
    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,1)
    %{ stop_prank_callable() %}

    tempvar sig_0 = 2308972034626336636719349429856080491071167795249356110568690290882108862811
    tempvar sig_1 = 1556538606777937571982722946990921832530755621376701759085777712875219599263

    #Player 1 picks third draft
    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,2)
    %{ stop_prank_callable() %}

    tempvar sig_0 = 1552475027609836231163567436411258206708638203156363634467910443714682550377
    tempvar sig_1 = 3070857222316929435788183174996116644134963409448821660465379102881411200477


    #Player 1 picks fourth draft
    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,0)
    %{ stop_prank_callable() %}


    tempvar sig_0 = 846447163438211075245868285691189676746677084400019995124571338304602474708
    tempvar sig_1 = 223394314070301378945451226556679369818523600632253468213259141831834708135

    #Player 1 picks fith draft
    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    let (local new_random_number) = IMain.select_card(main_address,1)
    %{ stop_prank_callable() %}
    

    #%{ print("new_random_number: ",ids.new_random_number) %}

    return()
end    

@external
func set_cards{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_main_address: felt):
    alloc_locals
    let (cards: Card*) = alloc()

    assert cards[0] = Card(0,0,0)
    assert cards[1] = Card(1,2,1)
    assert cards[2] = Card(1,1,2)
    assert cards[3] = Card(2,3,1)
    assert cards[4] = Card(2,1,3)
    assert cards[5] = Card(3,2,4)
    assert cards[6] = Card(3,4,2)
    assert cards[7] = Card(4,3,4)
    assert cards[8] = Card(4,5,2)
    assert cards[9] = Card(5,5,5)
    assert cards[10] = Card(5,4,6)
    assert cards[11] = Card(6,7,4)
    assert cards[12] = Card(6,5,7)
    assert cards[13] = Card(7,7,7)
    assert cards[14] = Card(7,6,8)
    assert cards[15] = Card(8,8,8)
    assert cards[16] = Card(8,6,10)
    assert cards[17] = Card(9,10,10)
    assert cards[18] = Card(9,8,13)
    assert cards[19] = Card(10,12,12)

    IMain.set_cards(
        _main_address,
        0,
        _cards_len=20, 
        _cards=cards
    )

    return()
end

func draw_initial_cards{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(main_address: felt,public_key_0: felt,public_key_1: felt):

    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    let (deck_index1,deck_index2,deck_index3) = IMain.initial_draw(main_address)
    %{ stop_prank_callable() %}

    %{ print("player0_deck_index1: ",ids.deck_index1) %}
    %{ print("player0_deck_index2: ",ids.deck_index2) %}
    %{ print("player0_deck_index3: ",ids.deck_index3) %}

    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    let (deck_index1,deck_index2,deck_index3) = IMain.initial_draw(main_address)
    %{ stop_prank_callable() %}

    %{ print("player1_deck_index1: ",ids.deck_index1) %}
    %{ print("player1_deck_index2: ",ids.deck_index2) %}
    %{ print("player1_deck_index3: ",ids.deck_index3) %}

    return()
end

func post_action{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(main_address: felt, public_key_0: felt, public_key_1: felt):
    alloc_locals
    let (actions0: felt*) = alloc()
    #Card placement
    #[1] hand index
    #[2] placement position
    #[3] signature_1
    #[4] signature_2

    #Card attack
    #[1] attacking card position (0-4)
    #[2] target position (0-5) can be card or hero

    #Player 0 plays a card
    assert actions0[0] = 0 
    assert actions0[1] = 0
    assert actions0[2] = 0
    assert actions0[3] = 3520946670207311696452862485752786087080542459149643480505056748727352413151
    assert actions0[4] = 1869180047908130272678343504614242117300102794495090870621043884084861351017 

    %{ stop_prank_callable = start_prank(ids.public_key_0,ids.main_address) %}
    let (test_res) = IMain.post_action(main_address,5,actions0)
    %{ stop_prank_callable() %}   

    let (actions1: felt*) = alloc()
    #Player 1 plays a card
    assert actions1[0] = 0 
    assert actions1[1] = 0
    assert actions1[2] = 0
    assert actions1[3] = 846447163438211075245868285691189676746677084400019995124571338304602474708
    assert actions1[4] = 223394314070301378945451226556679369818523600632253468213259141831834708135 
    #Player 1 attacks a card
    assert actions1[5] = 1 
    assert actions1[6] = 0
    assert actions1[7] = 0

    %{ stop_prank_callable = start_prank(ids.public_key_1,ids.main_address) %}
    let (test_res) = IMain.post_action(main_address,5,actions1)
    %{ stop_prank_callable() %}

    #let(player0_deck_len) = IMain.get_deck_len(main_address,0)
    #let(player1_deck_len) = IMain.get_deck_len(main_address,1)
    #%{ print("player0_deck_len: ",ids.player0_deck_len) %}
    #%{ print("player1_deck_len: ",ids.player1_deck_len) %}

    
    %{ print("test_res: ",ids.test_res) %}
    return()
end    

func normalize_pick{
    syscall_ptr : felt*, 
    pedersen_ptr : HashBuiltin*, 
    range_check_ptr}(_proven_card_pick: felt, _max_val : felt) -> (normalize_pick: felt):
    let (normalize_pick,_) = unsigned_div_rem((_proven_card_pick - 0)*_max_val,99-0)
    return(normalize_pick)
end   

%lang starknet
#########################################################
#########################################################
#                    GAME SETUP
#########################################################
#########################################################
#
#                    GAME BOARD
#
#HAND PLAYER0        2  5  0  0  0                        
#BOARD DAMAGE0       3  2  0  0  0  12  
#BOARD PLAYER0       0  0  11 14 0
#
#BOARD PLAYER1       0  21 0  15 13
#BOARD DAMAGE1       0  0  3  0  1  9
#HAND PLAYER1        2  5  7  0  0  
#TURN COUNTER1       11
#
#
#   ->>>>>>> For Hand and Board: empty spots are not 0 but DRAFT_LENGHT
#
#DECK0   1 2 3 4 5 6 7 ... n
#
#DECK1         " "
#
#   ALL OF THE ABOVE IS PACKED INTO ONE FELT
#
#Info     | HAND0,BOARD0,DAMAGE0,HAND1,BOARD1,DAMAGE1,TURN_COUNTER,Deck1,Deck2
#Bit Size | 0     25     50      80    105    130     160          165   195   
#
#
###########################################################
#                        DRAFT
#
#DRAFT0: [0] Card_Pick
#        [1] Card_Pick
#        [2] Card_Pick
#         .     ...
#         n     ...
#
#DRAFT1:       " "
#
#
#          n = DRAFT_LENGHT
#
#
#  We're using 2 storage slots per player for the draft :(
#
#########################################################
#########################################################
#                    STORAGE SETUP
#########################################################
#########################################################
################
#   BIT SIZES  #
################
const TURN_COUNTER_SIZE = 5 # 5 bits == max number 31
const CARD_ID_SIZE =  5         
const DECK_INDEX_SIZE =  5
const DAMAGE_AMOUNT_SIZE =  5      
const DRAFT_ID_SIZE = 5
const DECK_LEN_SIZE = 5
const HAND_SIZE = 25 # 5*5
const BOARD_SIZE = 25 # 5*5
const DAMAGE_SIZE = 30 # 5*6
#const DECK_SIZE = (DRAFT_LENGTH * DECK_INDEX_SIZE) + DECK_LEN_SIZE
#####################
#   BIT LOCATIONS   # 
#####################
# HAND0,BOARD0,DAMAGE0,HAND1,BOARD1,DAMAGE1,TURN_COUNTER,Deck1,Deck2
# 0     25     50      80    105    130     160          165   195                  
const HAND0_POSITION = 0
const BOARD0_POSITION = 25
const DAMAGE0_POSITION = 50
const HAND1_POSITION = 80
const BOARD1_POSITION = 105
const DAMAGE1_POSITION = 130
const TURN_COUNTER_POSITION = 160
const DECK0_POSITION = 165
const DECK1_POSITION = 195
##########################
#    ACTION INDICATORS   #
##########################
const Placement_action = 0
const Attack_action = 1
##########################
#      GAME SETTINGS     #
##########################
const HERO_HP = 20
const RANDOM_BASE = 1000000000000000000 # 1e18
const DRAFT_LENGTH = 5 #Kept short for testing purposes, otherwise ~30
const MAX_HAND_CARDS = 5
const MAX_BOARD_CARDS = 5
const NUMBER_OF_UNIQUE_CARDS = 20
#########################################################
#########################################################
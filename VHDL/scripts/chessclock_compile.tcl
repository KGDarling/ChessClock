#Delete the work library
exec rm -rf mti_work
#creat mti_work libary
vlib mti_work
#map it as "work"
vmap work mti_work
#Compile the chess clock components
vcom decimal_counter.vhd
vcom four_digit_counter.vhd
vcom chess_clock.vhd
#Compile the test bench with coverage
vcom +cover tb_zed_chess.vhd
#Launce QuestaSim
vsim -coverage -t ps work.TB_CHESS
echo "Compilation is over"
#Record everything
log -r *
add wave *
#Add state signal to the waveform
add wave -position insertpoint sim:/tb_chess/TEST_CHESS_CLOCK/STATE
run 5800ns
force -freeze WRONG_MATE '1'
run 10ns
force -freeze WRONG_MATE '0'
run 4090ns
force -freeze PLAYER1_STOP '1'
force -freeze PLAYER2_STOP '1'
run 10ns
force -freeze PLAYER1_STOP '0'
force -freeze PLAYER2_STOP '0'
run 1000ns

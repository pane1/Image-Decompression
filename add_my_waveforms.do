# add waves to waveform
add wave Clock_50
add wave uut/unit/state
add wave uut/top_state
add wave uut/unit/done
add wave uut/unit/start
add wave uut/done_n
add wave uut/m1_start
add wave uut/m1_done

add wave -divider {some label for my divider}
add wave -decimal uut/SRAM_address
add wave -hexadecimal uut/SRAM_read_data

add wave -hexadecimal uut/unit/sram_data_u
add wave -hexadecimal uut/unit/sram_data_v
add wave -hexadecimal uut/unit/Y_even
add wave -hexadecimal uut/unit/Y_odd
add wave -hexadecimal uut/unit/temp_u
add wave -hexadecimal uut/unit/temp_v
add wave -hexadecimal uut/SRAM_write_data
add wave -decimal uut/SRAM_we_n
add wave -decimal uut/unit/counter
add wave -decimal uut/unit/RGB_counter
add wave -decimal uut/unit/Y_counter
add wave -decimal uut/unit/lead_out_counter

add wave -divider {mult calculations}
add wave -decimal uut/unit/m1_op1
add wave -decimal uut/unit/m1_op2
add wave -decimal uut/unit/m1_res
add wave -decimal uut/unit/m2_op1
add wave -decimal uut/unit/m2_op2
add wave -decimal uut/unit/m2_res
add wave -decimal uut/unit/m3_op1
add wave -decimal uut/unit/m3_op2
add wave -decimal uut/unit/m3_res

add wave -divider {Y calculations}
add wave -hexadecimal uut/unit/yextend_even
add wave -hexadecimal uut/unit/yextend_odd
add wave -hexadecimal uut/unit/Y_calc_even
add wave -hexadecimal uut/unit/Y_calc_odd

add wave -divider {U calculations}
add wave -hexadecimal uut/unit/Ueven_prime
add wave -hexadecimal uut/unit/Uodd_prime

add wave -divider {V calculations}
add wave -hexadecimal uut/unit/Veven_prime
add wave -hexadecimal uut/unit/Vodd_prime

add wave -divider {RGB  calculations}
add wave -hexadecimal uut/unit/R_even
add wave -hexadecimal uut/unit/G_calc
add wave -hexadecimal uut/unit/G_reduce
add wave -hexadecimal uut/unit/G_even
add wave -hexadecimal uut/unit/B_even
add wave -hexadecimal uut/unit/R_odd
add wave -hexadecimal uut/unit/G_odd
add wave -hexadecimal uut/unit/B_odd


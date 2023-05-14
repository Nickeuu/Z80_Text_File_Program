	jp init
;start of heading 01h is the start of the file with the name
;start of text 02h is the start of the text
;end of text 03h is the end of the text
;file separator 1ch is at the end of the file to separate it
;ff for file save

	org 0400h
init:
;output to the screen the options
	ld hl, data_text_menu
	call output_function
input_choice:
	in a, (02h)
	ld b, "0"
	cp b
	jr z, exit_choice
	ld b, "1"
	cp b
	jr z, new_file_choice
	ld b, "2"
	cp b
	jp z, open_file_choice
	ld b, "3"
	cp b
	jp z, show_files_choice
	ld b, "4"
	cp b
	jp z, delete_file_choice
	jr input_choice
exit_choice:
	ld a, "0"
	out (01h), a
	call new_line_function
	call new_line_function
	halt
new_file_choice:
	ld a, "1"
	out (01h), a
	call new_line_function
	call new_line_function
nfc_start:
	call enter_name_function
	call search_file_function
	ld a, c
	ld b, 2		;2 if we found a file, else continue saving the file
	cp b
	jr nz, nfc_j1
	;reset input_name_pointer
	ld de, 0803h
	ld (input_name_pointer), de
;we found a duplicate
;erase introduced name
nfc_erase_name:
	ld a, (de)
	ld b, 0
	cp b
	jr z, nfc_en_end
;erase char after transfer
	ld a, 0
	ld (de), a
	inc de
	jr nfc_erase_name
nfc_en_end:
	ld hl, newfile_exists_data
	call new_line_function
	call output_function
	call new_line_function
	jr nfc_start
nfc_j1:
;continue by saving the name and starting the file write
	ld hl, (free_address_in_memory_pointer)
;insert start of heading 01h
	ld a, 01h
	ld (hl), a
	inc hl
;save address in file paging
	ex de, hl	; move hl in de
	ld hl, (free_address_in_file_paging_pointer)
;save the address of the file where the name starts in the file paging, after 01h
	ld (hl), e
	inc hl
	ld (hl), d
	inc hl
	ld (free_address_in_file_paging_pointer), hl
	ex de, hl	;move back the value in hl
;insert name
	ld de, (input_name_pointer)
nf_insert_name:
	ld a, (de)
	ld b, 0
	cp b
	jr z, nf_in_end
	ld (hl), a
;erase char after transfer
	ld a, 0
	ld (de), a
	inc hl
	inc de
	jr nf_insert_name
nf_in_end:
	ld a, 02h
	ld (hl), a
	inc hl
	call new_line_function
	call new_line_function
;now we can enter the write in file state
nf_write_file:
	in a, (02h)
	ld b, 0
	cp b
	jr z, nf_write_file
	ld c, a
;check for backspace
	ld b, 08h
	cp b
	jr z, nf_backspace
;check for file save FFh
	ld b, 0ffh
	cp b
	jr z, nf_save_file
;write char
	ld (hl), a
	out (01h), a
	inc hl
	ld a, (input_char_length)
	inc a
	ld (input_char_length), a
	jr nf_write_file
nf_backspace:
	ld a, (input_char_length)
	ld b, 0
	cp b
;if there is no char inputed
	jr z, nf_write_file
	ld (hl), 0
	dec hl
	dec a
	ld (input_char_length), a
	ld a, c
	out (01), a
	jr nf_write_file

nf_save_file:
	inc hl
	ld a, 03h
	ld (hl), a
	inc hl
	ld a, 1ch
	ld (hl), a
	inc hl
	ld (free_address_in_memory_pointer), hl
	ld a, 0
	ld (input_char_length), a	;set variable to 0
	call new_line_function
	call new_line_function
	ld hl, file_saved_data
	call output_function
	jp init

open_file_choice:
	ld a, "2"
	out (01h), a
	call new_line_function
	call new_line_function
ofc_start:
	call enter_name_function
	call search_file_function
	ld a, c
	ld b, 2
	cp b
	jr z, ofc_file_found
;file not found:
	call new_line_function
	ld hl, openfile_not_found_data
	call output_function
	call new_line_function
	jr ofc_start
ofc_file_found:
	call new_line_function
	call new_line_function
ofc_ff_start:
	inc de		;address of file found
	ld a, (de)
	ld b, 3
	cp b
	jr z, ofc_end	;end of file
	out (01h), a
	jr ofc_ff_start
ofc_end:
	call new_line_function
	call new_line_function
	jp init

show_files_choice:
	ld a, "3"
	out (01h), a
	call new_line_function
	call new_line_function
	ld hl, 1000h
sfc_start:
	ld e, (hl)
	inc hl
	ld d, (hl)
	ld a, d
	ld b, 0
	cp b
	jr z, sfc_j3	;if no file present
	inc hl
	ex de, hl
	ld b, 2
sfc_j2:
	ld a, (hl)
	cp b
	jr z, sfc_j1 	;end of file name
	out (01h), a
	inc hl
	jr sfc_j2	;get next char in mem
sfc_j1:
;get next file
	ex de, hl
	call new_line_function
	jr sfc_start
sfc_j3:
	call new_line_function
	jp init

delete_file_choice:
	ld a, "4"
	out (01h), a
	call new_line_function
	call new_line_function
dfc_start:
	call enter_name_function
	call search_file_function
	ld a, c
	ld b, 2
	cp b
	jr z, dfc_file_found
;file not found:
	call new_line_function
	ld hl, openfile_not_found_data
	call output_function
	call new_line_function
	jr dfc_start
dfc_file_found:
	call new_line_function
	call new_line_function
	ld h, d
	ld l, e
	dec de
	dec de
	;get initial starting point of file (in de)
	ld b, 1ch
dfc_j2:
	inc hl
	ld a, (hl)
	cp b
	jr z, dfc_j1	;end of file
	jr dfc_j2

;hl contains end of the file and is pointer to get the next data to be transfered
;de contains start of the file and is pointer to put the data transfered
;aux_index1 is pointer to chech with :de: if we are at the end of the deleted file
;
;transfer all data untill we reach the end of the file then check if we have another files after to move them aswell
;	!!!Don't alter hl and de in data transfer!!!


dfc_j1:
;end of file
	ld (aux_index1), hl	;save end of the file in aux1
	inc hl
;check for pointer matching the end
dfc_j1_start:
	ld bc, (aux_index1)
	ld a, d
	cp b			;cp high addresses
	jr nz, dfc_j3
	;coresponds
	ld a, e
	ld b, c			;cp low adresses
	cp b
	jr nz, dfc_j3
	;coresponds - end of file
	;check for more data after file
	ld a, (hl)
	ld (de), a
	inc hl
	inc de
	ld a, (hl)
	ld b, 0
	cp b
	jr z, dfc_data_end

dfc_j3:
;does'nt coresponds (didn't came at the end)
	ld a, (hl)
	ld (de), a
	inc hl
	inc de
	jr dfc_j1_start

dfc_data_end:
;end of data transfer



enter_name_function:
	ld hl, insert_name_data
	call output_function
enf_start:
	in a, (02h)
	ld b, 0
	cp b
	jr z, enf_start
	ld c,a	;save c the value of the input
;check for backspace
	ld b, 08h
	cp b
	jr z, enf_backspace
;check for enter
	ld b, 0dh
	cp b
	jr z, enf_enter
;continue with char
	ld b, 0fh
	ld a, (input_char_length)
;if there are allready 15 characters saved then go to start
	cp b
	jr z, enf_start
	ld a, c
	out (01h), a
	ld hl, (input_name_pointer)
	ld (hl), a
	inc hl
	ld (input_name_pointer), hl
	ld a, (input_char_length)
	inc a
	ld (input_char_length), a
	jr enf_start

enf_backspace:
	ld a, (input_char_length)
	ld b, 0
	cp b
	jr z, enf_start
;there is character to be deleted
;output the backspace char
	ld a, c
	out (01h), a
	ld hl, (input_name_pointer)
	dec hl
	ld a, 0
	ld (hl), a
	ld (input_name_pointer), hl
	ld a, (input_char_length)
	dec a
	ld (input_char_length), a
	jr enf_start
enf_enter:
	ld a, (input_char_length)
	ld b, 0
	cp b
;if there is no characters in the name entered, return to start
	jr z, enf_start
;if there is at least one character, reset variables and return from function
	ld hl, input_char_length
	ld (hl), 0
	ld hl, 0803h	;set the default starting point
	ld (input_name_pointer), hl
	ret

output_function:
	ld a, (hl)
	ld b, 0
	cp b
;if 0 jp
	ret z
;if !0 continue
	out (01h), a
	inc hl
	jr output_function

search_file_function:
	ld hl, file_paging
;check to see if there are files in memory
;c = 1 if there are no files in mem or no match
;c = 2 if there is a match
sff_start:
	ld a, (hl)
	ld b, 0
	cp b
	jr nz, sff_yes_files ;a != 0
;no files
	ld c, 1
	ret
sff_yes_files:
;ld address of the file paging in de
	ld e, (hl)
	inc hl
	ld d, (hl)
	inc hl
	ld (aux_index1), hl	;save next paged file in aux index 1
	ld hl, (input_name_pointer)
sff_j3:
	ld a, (de)
	ld b, (hl)
	cp b
	jr z, sff_match	;letter corresponds

;hl contains address to the name introduced
;de contains address to the current paged file

;letter doesn't corresponds
	jr sff_j2
sff_match:
;increase pointers to the next letter
;check if both the letters are 0 to check for the end if not continue
;if all leters corresponds and 0 is present then there is a match -> save address of the file
	inc hl
	inc de
	ld a, (de)
	ld b, 2		;end of name
	cp b
	jr nz, sff_j1	;if the name introduced has more chars
	ld a, (hl)
	ld b, 0
	cp b
	jr nz, sff_j2	;if the namefile has more chars
;we have found a match
	ld c, 2
	ret
sff_j1:
	ld a, (hl)
	ld b, 0
	cp b
	jr nz, sff_j3	;if there are more chars in both locations
sff_j2:
;no match here
	ld de, 0803h
	ld (input_name_pointer), de
	ld hl, (aux_index1)	;get back the saved address
	jr sff_start

new_line_function:
	ld a, 0dh
	out (01h), a
	ret

	org 0800h
input_char_length:
	db 0
input_name_pointer:
	dw 0803h
input_name:
	db 0

	org 0812h
free_address_in_memory_pointer:
	dw 2000h
free_address_in_file_paging_pointer:
	dw 1000h
aux_index1:
	dw 0000h

	org 0900h
data_text_menu:
	db 54H,65H,78H,74H,20H,66H,69H,6CH,65H,20H,65H,64H,69H,74H,6FH,72H,20H,56H,31H,2EH,30H,0AH,0AH,4DH,65H,6EH,75H,0AH,31H,2EH,20H,4EH,65H,77H,20H,66H,69H,6CH,65H,0AH,32H,2EH,20H,4FH,70H,65H,6EH,20H,66H,69H,6CH,65H,0AH,33H,2EH,20H,53H,68H,6FH,77H,20H,66H,69H,6CH,65H,73H,0AH,34H,2EH,20H,44H,65H,6CH,65H,74H,65H,20H,66H,69H,6CH,65H,0AH,30H,2EH,20H,45H,78H,69H,74H,0AH,0AH,59H,6FH,75H,72H,20H,63H,68H,6FH,69H,63H,65H,3AH,20H,0
insert_name_data:
	db 49H,6EH,73H,65H,72H,74H,20H,6EH,61H,6DH,65H,20H,28H,6DH,61H,78H,20H,31H,35H,20H,63H,68H,61H,72H,61H,63H,74H,65H,72H,73H,29H,3AH,0AH,0
file_saved_data:
	db 46H,69H,6CH,65H,20H,73H,61H,76H,65H,64H,21H,0AH,0
newfile_exists_data:
	db 54H,68H,65H,20H,66H,69H,6CH,65H,20H,65H,78H,69H,73H,74H,73H,2CH,20H,70H,6CH,65H,61H,73H,65H,20H,65H,6EH,74H,65H,72H,20H,61H,6EH,6FH,74H,68H,65H,72H,20H,6EH,61H,6DH,65H,21H,0
openfile_not_found_data:
	db 54H,68H,65H,20H,66H,69H,6CH,65H,20H,77H,61H,73H,20H,6EH,6FH,74H,20H,66H,6FH,75H,6EH,64H,2CH,20H,70H,6CH,65H,61H,73H,65H,20H,65H,6EH,74H,65H,72H,20H,61H,20H,76H,61H,6CH,69H,64H,20H,66H,69H,6CH,65H,21H,0

	org 1000h
file_paging:
	db 0
	org 2000h
files_saved_in_memory:
	db 0

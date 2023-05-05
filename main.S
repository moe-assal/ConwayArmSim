/* 
conventions:
	x0->x4: pass vars to funcs
	x5: return value
	lr (x30): saved in stack
	sp: preserved
*/

.data
	sector_size:
		.quad 67108864
// constant literals
	hex_characters: 
		.ascii "0123456789abcdef"
	new_line_c: 
		.ascii "\n"
	comma_c: 
		.ascii ","
	generation_c: 
		.ascii "generation\n"
	negative_sign_c: 
		.ascii "-"
// global vars
	start:
		.quad 0
	end_old:
		.quad 0
	end:
		.quad 0
// driver tree
	tree:
		.quad 0 // pointer to tree
	i:
		.quad 0
	num_of_gen:
		.quad 0

.bss
	sector_base:
		.space 67108864

    .text
    .global _start


_start:
	// set num_of_gen from command line arguments
	ldr x0, [sp, #16]
    bl read_num
    adr x0, num_of_gen
    str x5, [x0]
    
	bl initialize
	// 	r = createTree();
	bl createTree
	adr x0, tree
	str x5, [x0]
	
	// insert nodes
	adr x0, tree
	ldr x0, [x0]
	mov x1, #0
	mov x2, #0
	bl insert
	
	adr x0, tree
	ldr x0, [x0]
	mov x1, #0
	mov x2, #1
	bl insert
	
	adr x0, tree
	ldr x0, [x0]
	mov x1, #0
	mov x2, #-1
	bl insert

	adr x0, tree
	ldr x0, [x0]
	mov x1, #1
	mov x2, #-1
	bl insert
	
	adr x0, tree
	ldr x0, [x0]
	mov x1, #-1
	mov x2, #0
	bl insert

	
	driver_for:
	
		// i < num_of_gen
		adr x0, i
		ldr x1, [x0]
		adr x29, num_of_gen
		ldr x29, [x29]
		cmp x1, x29
		bge end_driver_for
		
		// i++
		adr x0, i
		ldr x1, [x0]
		add x1, x1, #1
		str x1, [x0]
		
		adr x0, tree
		ldr x0, [x0]
		bl printTreeToFile
		
		adr x0, tree
		ldr x0, [x0]
		bl to_next_gen
		adr x0, tree
		str x5, [x0]
		
		bl free_last_gen
		
	
	b driver_for
	end_driver_for:
	
	// make the exit system call
    mov x0, #0              // exit status code
    mov x8, #93
    svc #0


allocate:
	/* size passed in register x0, return value in x5 */
	
	adr x8, end // save end address in x8
	// void *return_value = end	
	ldr x5, [x8]
	
	// end += size
	add x6, x5, #0
	add x6, x6, x0

	
	// sector_base + SECTOR_SIZE in x7
	adr x7, sector_base
	adr x9, sector_size // load sector_size
	ldr x10, [x9]
	add x7, x7, x9
	// if(end > sector_base + SECTOR_SIZE)
	cmp x6, x7
	
	ble end_if_end_more_than_sector
		adr x5, sector_base // return_value = sector_base
		add x6, x5, x0 // end = sector_base + size
	end_if_end_more_than_sector:
	
	str x6, [x8] // store new end value
	
	ret 
	

free_last_gen:
	// start = end_old
	adr x6, start // get start pointer
	adr x7, end_old // get end pointer
	ldr x7, [x7] // get end value
	str x7, [x6] // store in start
	
	// end_old = end
	adr x6, end_old // get start pointer
	adr x7, end // get end pointer
	ldr x7, [x7] // get end value
	str x7, [x6] // store in start

	ret 

initialize:
	// start = end_old = end = sector_base
	adr x6, start
	adr x7, end_old
	adr x8, end
	adr x9, sector_base
	
	str x9, [x6]
	str x9, [x7]
	str x9, [x8]
	
	ret

newNode:
	/* x in x0, y in x1, output in x5 */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// store x0, x1
	sub sp, sp, #16 // allocate memory on stack
	str x0, [sp, #8]
	str x1, [sp, #0]
	// 	struct Node *n = allocate(sizeof(struct Node));
	mov x0, #32 // argument size for allocate
	bl allocate
	// restore x0, x1
	ldr x0, [sp, #8]
	ldr x1, [sp, #0]
	add sp, sp, #16 // free stack space
	
	str x0, [x5, #0] // n->x = x
	str x1, [x5, #8] // n->y = y
	str xzr, [x5, #16] // n->left = 0
	str xzr, [x5, #24] // n->right = 0

	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space

	ret 


createTree:
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// 	struct Tree* temp = allocate(sizeof(struct Tree))
	mov x0, #16 // argument size for allocate
	bl allocate
	
	str xzr, [x5, #0] // temp->size = 0
	str xzr, [x5, #8] // temp->root = NULL
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space
	
	ret

newQNode:
	/* takes node pointer as x0 input */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// store x0
	sub sp, sp, #8
	str x0, [sp, #0]
	// 	struct QNode* temp = allocate(sizeof(struct QNode))
	mov x0, #16 // argument size for allocate
	bl allocate
	// load x0
	ldr x0, [sp, #0]
	add sp, sp, #8
	
	str x0, [x5, #0] // temp->value = value
	str xzr, [x5, #8] // temp->next = NULL
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space
	
	ret


createQueue:
	/* takes node pointer in x0, returns pointer in x5 */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// no need to store value (x0) as it is no longer used
    // struct QNode* temp = newQNode(value);
	// argument already in x0
	bl newQNode
	
	// store x5 (temp)
	sub sp, sp, #8
	str x5, [sp, #0]
	// struct Queue* q = allocate(sizeof(struct Queue))
	mov x0, #24 // argument size for allocate
	bl allocate
	// load x5 to x6
	ldr x6, [sp, #0]
	add sp, sp, #8
	
	/* x5 is q, x6 is temp */
	
	// q->size=1
	mov x7, #1
	str x7, [x5, #0]
	str x6, [x5, #8] // q->front = temp
	str x6, [x5, #16] // q->rear = temp
	
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space
	
	ret


enQueue:
	/* q in x0, value in x1 */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// save x0, x1
	sub sp, sp, #16
	str x0, [sp, #8]
	str x1, [sp, #0]
	// struct QNode* temp = newQNode(value);
	mov x0, x1 // set argument
	bl newQNode
	
	// load x0, x1	
	ldr x0, [sp, #8]
	ldr x1, [sp, #0]
	add sp, sp, #16
	
	/* temp in x5 */
	
	// if(q->size == 0)
	ldr x6, [x0, #0] // q->size value
	
	
	cmp x6, #0
	bne exit_if_size_null
	
		// q->size++
		add x6, x6, #1
		str x6, [x0, #0]
		// q->rear = q->front = temp
		str x5, [x0, #8]
		str x5, [x0, #16]
		
		ldr x30, [sp, #0] // restore lr 
		add sp, sp, #8 // free stack space
	
		ret
	exit_if_size_null:

	// q->size++
	add x6, x6, #1
	str x6, [x0, #0]

	ldr x7, [x0, #16] // get q->rear
	str x5, [x7, #8] // q->rear->next = temp
	str x5, [x0, #16] // q->rear = temp
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space
	
	ret

deQueue:
	/* q in x0, out in x5 */
	
	ldr x6, [x0, #8] // struct QNode* temp = q->front
	ldr x7, [x6, #8] // q->front->next
	str x7, [x0, #8] // q->front = q->front->next;
	
	// q->size--
	ldr x8, [x0, #0] // q->size value
	sub x8, x8, #1
	str x8, [x0, #0]
	
	ldr x5, [x6, #0] // value = temp->value
	
	ret


print_num_to_file:
	/* num in x0 */
	// code changed for 64 bit compatibility
	
	// set x6 as 0x8000000000000000
	mov x6, xzr
	add x6, x6, #1
	lsl x6, x6, #63
	
	// if (num & 0x80000000)
	and x7, x0, x6
	cmp x7, xzr
	beq end_if_negative
	
	if_negative:
		// save register x0
		sub sp, sp, #8
		str x0, [sp, #0]

		// print negative sign
	    mov x0, #1
		adr x1, negative_sign_c
		mov x2, #1
		mov x8, #64
		svc #0
		
		// load x0
		ldr x0, [sp, #0]
		add sp, sp, #8
		
		// twos complement
		mov x11, xzr
		sub x11, x11, #1 // save -1 in x11
		eor x0, x0, x11 // logical not
		add x0, x0, #1 // add 1
		
	end_if_negative:

	mov x8, xzr // set i to zero
	print_num_loop:
		cmp x8, #16 // i<16
		bge end_print_num_loop 
		
		// loop code here
		mov x12, #60
		lsr x9, x0, x12 // unsigned offset = num >> 28
		adr x10, hex_characters
		add x10, x10, x9 // hex_characters + offset
		
		// save x8, x0
		sub sp, sp, #16
		str x0, [sp, #0]
		str x8, [sp, #8]
		
		// 	write(1, hex_characters + offset, 1);
	    mov x0, #1
		mov x1, x10
		mov x2, #1
		mov x8, #64
		svc #0
		
		// load x8, x0
		ldr x0, [sp, #0]
		ldr x8, [sp, #8]
		add sp, sp, #16
		
		lsl x0, x0, #4 // num = num << 4
		add x8, x8, #1 // i++
		b print_num_loop
	end_print_num_loop:
	
	ret


print_new_line:
	mov x0, #1
    adr x1, new_line_c
    mov x2, #1
    mov x8, #64
    svc #0
    
	ret 


search:
	/* tree pointer in x0, x in x1, y in x2, out is boolean in x5 */ 
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// if(tree->size == 0) return 0;
	ldr x6, [x0, #0] // tree->size
	cmp x6, xzr
	bne dont_enter_if_0
	mov x5, #0
	b exit_search
	dont_enter_if_0:
	
	
	// x6 temp, x7 depth, x8 cd
	ldr x6, [x0, #8] // struct Node* temp = tree->root;
	mov x7, xzr // depth = 0
	mov x8, xzr // cd = 0
	
	do_while:
		// 	if(temp->x == x && temp->y == y) return 1;
		ldr x11, [x6, #0] // temp->x
		sub x11, x11, x1 // temp->x - x
		ldr x9, [x6, #8] // temp->y
		sub x9, x9, x2 // temp->y - y
		
		orr x10, x11, x9 // temp->y - y or temp->x - x == 0
		cmp x10, xzr
		
		bne dont_enter_if_1
		mov x5, #1
		b exit_search
		dont_enter_if_1:
		
		// if(cd==0)
		cmp x8, xzr
		bne else_cd_0
		if_cd_0:
		
			// if(temp->x < x)
			ldr x9, [x6, #0] // temp->x
			cmp x9, x1
			bge else_less_x
			if_less_x:
				
				
				// if(!temp->left) return 0
				ldr x9, [x6, #16] // temp->left
				cmp x9, xzr
				bne else1
				mov x5, #0
				b exit_search
				// else temp = temp->left;
				else1:
				mov x6, x9
				
				b end_less_x
			else_less_x:
				
				// if(!temp->right) return 0
				ldr x9, [x6, #24] // temp->right
				cmp x9, xzr
				bne else2
				mov x5, #0
				b exit_search
				// else temp = temp->right;
				else2:
				mov x6, x9
				 
			end_less_x:
			
			b end_cd_0
		else_cd_0:
			// else code here
			// if(temp->y < y)
			ldr x9, [x6, #8] // temp->y
			cmp x9, x1
			bge else_less_y
			if_less_y:
			
				// if(!temp->left) return 0
				ldr x9, [x6, #16] // temp->left
				cmp x9, xzr
				bne else3
				mov x5, #0
				b exit_search
				// else temp = temp->left;
				else3:
				mov x6, x9
				 
				b end_less_y
			else_less_y:
				
				// if(!temp->right) return 0
				ldr x9, [x6, #24] // temp->right
				cmp x9, xzr
				bne else4
				mov x5, #0
				b exit_search
				// else temp = temp->right;
				else4:
				mov x6, x9
			end_less_y:
		end_cd_0:
	
	// depth++;
	add x7, x7, #1
	// cd = depth % 2 (xor with 1)		
	mov x10, xzr
	add x9, x10, #1
	eor x8, x8, x9
	
	b do_while
	exit_do_while:
	
	exit_search:
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space

	ret


insert:
	/* tree pointer in x0, x in x1, y in x2 */ 
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// store parameters
	sub sp, sp, #24
	str x0, [sp, #0]
	str x1, [sp, #8]
	str x2, [sp, #16]

	// if(search(tree, x, y)) return
	bl search // args already in place
	cmp x5, xzr
	bne end_insert
	
	
	// create new node for later usage and save in x20
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	bl newNode
	mov x20, x5
	
	// return parameters to registers
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	
	
	// if(tree->size == 0)
	ldr x6, [x0, #0] // tree->size
	cmp x6, xzr
	bne size_isnt_null
		str x20, [x0, #8] // tree->root = newNode(x, y)
		add x6, x6, #1 // tree->size++
		str x6, [x0, #0] 
		b end_insert // return
	size_isnt_null:
	
	// x6 temp, x7 depth, x8 cd
	ldr x6, [x0, #8] // struct Node* temp = tree->root;
	mov x7, xzr // depth = 0
	mov x8, xzr // cd = 0
	
	do_while_insert:
	
	// if(cd==0)
	cmp x8, xzr
	bne else_cd_0_insert
	if_cd_0_insert:
	
		// if(temp->x < x)
		ldr x9, [x6, #0] // temp->x
		cmp x9, x1
		bge else_less_x_insert
		if_less_x_insert:
			
			// if(!temp->left)
			ldr x9, [x6, #16] // temp->left
			cmp x9, xzr
			bne else1_insert
			str x20, [x6, #16] // temp->left = newNode(x, y)
			b exit_do_while_insert // break
			// else temp = temp->left;
			else1_insert:
			mov x6, x9
			
			b end_less_x_insert
		else_less_x_insert:
			
			// if(!temp->right) return 0
			ldr x9, [x6, #24] // temp->right
			cmp x9, xzr
			bne else2_insert
			str x20, [x6, #24] // temp->right = newNode(x, y)
			b exit_do_while_insert // break
			// else temp = temp->right;
			else2_insert:
			mov x6, x9
			 
		end_less_x_insert:
		
		b end_cd_0_insert
	else_cd_0_insert:
		// else code here
		// if(temp->y < y)
		ldr x9, [x6, #8] // temp->y
		cmp x9, x1
		bge else_less_y_insert
		if_less_y_insert:
			
			// if(!temp->left)
			ldr x9, [x6, #16] // temp->left
			cmp x9, xzr
			bne else3_insert
			str x20, [x6, #16] // temp->left = newNode(x, y)
			b exit_do_while_insert // break
			// else temp = temp->left;
			else3_insert:
			mov x6, x9
			 
			b end_less_y_insert
		else_less_y_insert:
			
			// if(!temp->right) return 0
			ldr x9, [x6, #24] // temp->right
			cmp x9, xzr
			bne else4_insert
			str x20, [x6, #24] // temp->right = newNode(x, y)
			b exit_do_while_insert // break
			// else temp = temp->right;
			else4_insert:
			mov x6, x9
			
		end_less_y_insert:
	end_cd_0_insert:

	// depth++;
	add x7, x7, #1
	// cd = depth % 2 (xor with 1)		
	mov x10, xzr
	add x9, x10, #1
	eor x8, x8, x9
		
	b do_while_insert
	exit_do_while_insert:
	
	// tree->size++
	ldr x6, [x0, #0] // tree->size
	add x6, x6, #1 // tree->size++
	str x6, [x0, #0] 
	
	end_insert:
	add sp, sp, #24 // free saved parameters
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space

	ret


num_of_neighbors:
	/* inputs tree in x0, x in x1, y in x2 */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// store parameters and initialize sum
	sub sp, sp, #32
	str x0, [sp, #0]
	str x1, [sp, #8]
	str x2, [sp, #16]
	str xzr, [sp, #24]
	
	// load values from stack and call search then update sum (x-1, y-1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	sub x1, x1, #1
	sub x2, x2, #1
	bl search
	ldr x6, [sp, #24]
	add x6, x6, x5
	str x6, [sp, #24]
	
	// load values from stack and call search then update sum (x-1, y)
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	sub x1, x1, #1
	bl search
	ldr x6, [sp, #24]
	add x6, x6, x5
	str x6, [sp, #24]
	
	// load values from stack and call search then update sum (x-1, y+1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	sub x1, x1, #1
	add x2, x2, #1
	bl search
	ldr x6, [sp, #24]
	add x6, x6, x5
	str x6, [sp, #24]
	
	// load values from stack and call search then update sum (x, y - 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	sub x2, x2, #1
	bl search
	ldr x6, [sp, #24]
	add x6, x6, x5
	str x6, [sp, #24]
	
	// load values from stack and call search then update sum (x, y + 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	add x2, x2, #1
	bl search
	ldr x6, [sp, #24]
	add x6, x6, x5
	str x6, [sp, #24]
	
	// load values from stack and call search then update sum (x + 1, y - 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	add x1, x1, #1
	sub x2, x2, #1
	bl search
	ldr x6, [sp, #24]
	add x6, x6, x5
	str x6, [sp, #24]
	
	// load values from stack and call search then update sum (x + 1, y)
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	add x1, x1, #1
	bl search
	ldr x6, [sp, #24]
	add x6, x6, x5
	str x6, [sp, #24]
	
	// load values from stack and call search then update sum (x + 1, y + 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	add x1, x1, #1
	add x2, x2, #1
	bl search
	ldr x6, [sp, #24]
	add x6, x6, x5
	str x6, [sp, #24]
	
	ldr x5, [sp, #24] // get final sum
	
	add sp, sp, #32 // free local vars
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space

	ret


is_alive:
	/* old_gen in x0, x in x1, y in x2 */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// store parameters and allocate space for num of neighbors
	sub sp, sp, #32
	str x0, [sp, #0]
	str x1, [sp, #8]
	str x2, [sp, #16]
	
	// call num of neighbors and save return value
	bl num_of_neighbors // vars already in place
	str x5, [sp, #24]
	
	// call search
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	bl search
	
	// load all data in stack and free it
	ldr x0, [sp, #0]
	ldr x1, [sp, #8]
	ldr x2, [sp, #16]
	ldr x3, [sp, #24]
	add sp, sp, #32
	
	/* state: x0->x2 (params), x3 num, x5 was_alive */
	// num == 3 in x8
	mov x6, #1
	mov x7, #0
	cmp x3, #3 // num == 3
	csel x8, x6, x7, eq // x8 = (num==3)? #1 : #0
	

	
	// num == 2 in x9
	cmp x3, #2 // num == 2
	csel x9, x6, x7, eq // x9 = (num==2)? #1 : #0
	

	orr x10, x8, x9 // x10 = x8 || x9
	and x11, x10, x5 // (num == 3 || num == 2) && was_alive
	

	// !was_alive boolean in x13
	eor x13, x5, #1
	
	and x14, x13, x8 // num == 3 && !was_alive

	orr x5, x14, x11 // return value
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space

	ret


process_node:
	/* x0 old_gen, x1 new_gen, x2 n */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	// save x0, x1, x2->x, x2->y
	sub sp, sp, #32
	str x0, [sp, #0]
	str x1, [sp, #8]
	ldr x3, [x2, #0] // n->x	
	str x3, [sp, #16]
	
	ldr x3, [x2, #8] // n->y
	str x3, [sp, #24]
	
	// if(is_alive(old_gen, x - 1, y - 1)) insert(new_gen, x - 1, y - 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	sub x1, x1, #1
	sub x2, x2, #1
	bl is_alive
	cmp x5, #0
	beq dont_insert_xm1_ym1
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	sub x1, x1, #1
	sub x2, x2, #1
	bl insert
	dont_insert_xm1_ym1:
	
	
	// if(is_alive(old_gen, x - 1, y)) insert(new_gen, x - 1, y)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	sub x1, x1, #1
	bl is_alive
	cmp x5, #0
	beq dont_insert_xm1_y
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	sub x1, x1, #1
	bl insert
	dont_insert_xm1_y:
	
	// if(is_alive(old_gen, x - 1, y+1)) insert(new_gen, x - 1, y+1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	sub x1, x1, #1
	add x2, x2, #1
	bl is_alive
	cmp x5, #0
	beq dont_insert_xm1_yp1
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	sub x1, x1, #1
	add x2, x2, #1
	bl insert
	dont_insert_xm1_yp1:
	
	// if(is_alive(old_gen, x, y - 1)) insert(new_gen, x, y - 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	sub x2, x2, #1
	bl is_alive
	cmp x5, #0
	beq dont_insert_x_ym1
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	sub x2, x2, #1
	bl insert
	dont_insert_x_ym1:
	

	// if(is_alive(old_gen, x, y + 1)) insert(new_gen, x, y + 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	add x2, x2, #1
	bl is_alive
	cmp x5, #0
	beq dont_insert_x_yp1
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	add x2, x2, #1
	bl insert
	dont_insert_x_yp1:
	


	// if(is_alive(old_gen, x + 1, y - 1)) insert(new_gen, x + 1, y - 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	add x1, x1, #1
	sub x2, x2, #1
	bl is_alive
	cmp x5, #0
	beq dont_insert_xp1_ym1
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	add x1, x1, #1
	sub x2, x2, #1
	bl insert
	dont_insert_xp1_ym1:
	
	
	// if(is_alive(old_gen, x, y)) insert(new_gen, x, y)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]	
	ldr x2, [sp, #24]
	bl is_alive
	cmp x5, #0
	beq dont_insert_x_y
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	bl insert
	dont_insert_x_y:
	
	
	// if(is_alive(old_gen, x + 1, y)) insert(new_gen, x + 1, y)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	add x1, x1, #1
	bl is_alive
	cmp x5, #0
	beq dont_insert_xp1_y
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	add x1, x1, #1
	bl insert
	dont_insert_xp1_y:
	
	// if(is_alive(old_gen, x + 1, y + 1)) insert(new_gen, x + 1, y + 1)
	ldr x0, [sp, #0]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	add x1, x1, #1
	add x2, x2, #1
	bl is_alive
	cmp x5, #0
	beq dont_insert_xp1_yp1
	ldr x0, [sp, #8]
	ldr x1, [sp, #16]
	ldr x2, [sp, #24]
	add x1, x1, #1
	add x2, x2, #1
	bl insert
	dont_insert_xp1_yp1:	
	
	add sp, sp, #32 // free local vars
		
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space

	ret
	

printTreeToFile:
	/* tree in x0 */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr
	
	sub sp, sp, #24 // local vars
	str x0, [sp, #0] // tree
	str xzr, [sp, #8] // q
	str xzr, [sp, #16] // n
	
	// 	write(1, generation_c, 11)
	mov x0, #1
    adr x1, generation_c
    mov x2, #11
    mov x8, #64
    svc #0
    
    // q = createQueue(tree->root)
    ldr x0, [sp, #0]
    ldr x0, [x0, #8]
    bl createQueue
    str x5, [sp, #8]
    
    while_print_size_not_null:
    
		// n = deQueue(q)
		ldr x0, [sp, #8]
		bl deQueue
		str x5, [sp, #16]
		
		// if(n->left)
		ldr x6, [sp, #16]
		ldr x6, [x6, #16]
		cmp x6, #0
		beq print_dont_enqueue_left
		// enQueue(q, n->left)
		ldr x0, [sp, #8]
		ldr x1, [sp, #16]
		ldr x1, [x1, #16]
		bl enQueue
		print_dont_enqueue_left:
		
		// if(n->right)
		ldr x6, [sp, #16]
		ldr x6, [x6, #24]
		cmp x6, #0
		beq print_dont_enqueue_right
		// enQueue(q, n->right)
		ldr x0, [sp, #8]
		ldr x1, [sp, #16]
		ldr x1, [x1, #24]
		bl enQueue
		print_dont_enqueue_right:
		
		// print_num_to_file(n->x)
		ldr x0, [sp, #16]
		ldr x0, [x0, #0]
		bl print_num_to_file
		
		// write(1, comma_c, 1)
		mov x0, #1
		adr x1, comma_c
		mov x2, #1
		mov x8, #64
		svc #0
		
		// print_num_to_file(n->y);
		ldr x0, [sp, #16]
		ldr x0, [x0, #8]
		bl print_num_to_file
		
		bl print_new_line
		
		
		ldr x0, [sp, #8] // q
		ldr x0, [x0, #0] // q->size
		cmp x0, #0

    	bne while_print_size_not_null
	
	add sp, sp, #24 // free local vars
		
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space

	ret


to_next_gen:
	/* old_gen in x0 */
	sub sp, sp, #8 // allocate memory on stack
	str x30, [sp, #0] // save lr

	sub sp, sp, #32 // local vars
	str x0, [sp, #0] // old_gen
	str xzr, [sp, #8] // q
	str xzr, [sp, #16] // n
	bl createTree
	str x5, [sp, #24] // new_gen
	
    
    // q = createQueue(old_gen->root)
    ldr x0, [sp, #0]
    ldr x0, [x0, #8]
    bl createQueue
    str x5, [sp, #8]
    
    while_tonext_size_not_null:
    
		// n = deQueue(q)
		ldr x0, [sp, #8]
		bl deQueue
		str x5, [sp, #16]
		
		// if(n->left)
		ldr x6, [sp, #16]
		ldr x6, [x6, #16]
		cmp x6, #0
		beq tonext_dont_enqueue_left
		// enQueue(q, n->left)
		ldr x0, [sp, #8]
		ldr x1, [sp, #16]
		ldr x1, [x1, #16]
		bl enQueue
		tonext_dont_enqueue_left:
		
		// if(n->right)
		ldr x6, [sp, #16]
		ldr x6, [x6, #24]
		cmp x6, #0
		beq tonext_dont_enqueue_right
		// enQueue(q, n->right)
		ldr x0, [sp, #8]
		ldr x1, [sp, #16]
		ldr x1, [x1, #24]
		bl enQueue
		tonext_dont_enqueue_right:
		

		// process_node(old_gen, new_gen, n);
		ldr x0, [sp, #0]
		ldr x1, [sp, #24]
		ldr x2, [sp, #16]
		bl process_node
		
		ldr x0, [sp, #8] // q
		ldr x0, [x0, #0] // q->size
		cmp x0, #0

    	bne while_tonext_size_not_null
	
	ldr x5, [sp, #24]
	add sp, sp, #32 // free local vars
	
	ldr x30, [sp, #0] // restore lr 
	add sp, sp, #8 // free stack space

	ret


read_num:
	/* takes x0 a pointer to a char array of numbers, return in x5 */
	// value = 0; for (char c : str) { value = value*10 + c - '0' }; 
	mov x5, #0
	
	read_num_for:
		
		// char in x6
		ldr x6, [x0]
		and x6, x6, #0xff
		
		// check if char is null
		cmp x6, #0
		beq end_read_num_for
		
		mov x9, #10
		mul x5, x5, x9
		sub x6, x6, #48 // subtract ascii of '0'
		add x5, x5, x6
		

		// increment pointer by a byte
		add x0, x0, #1
		b read_num_for
	end_read_num_for:
	
	ret


#include<stdio.h>
#include<stdlib.h>
#include<unistd.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<fcntl.h>  


// constant literals
const char* hex_characters = "0123456789abcdef"; // used to map binary codes (offset) to ascii chars
const char* filename = "simulation";
const char* new_line_c = "\n";
const char* comma_c = ",";
const char* generation_c = "generation\n";
const char* negative_sign_c = "-";

/* 
The following code has to do with the memory manager

- allocate:
	takes size (unit in bytes) and returns an address to the allocated memory
- free_last_gen:
	called after a generation is finished simulating and the generation before it 
	is no longer needed. Cleans up the memory.
- initialize:
	initializes the memory and allocates SECTOR_SIZE bytes

*/

#define SECTOR_SIZE 33554432 // 2^25 bytes ~ 33.55 Megabytes

// driver tree
struct Tree *r;
// set as global variables
void* sector_base;
void* start;
void* end_old; // end of gen_0 and start of gen_1
void* end; // end of gen_1

int file_descriptor;  // output file

void* allocate(unsigned size){ // unit in bytes
	void *return_value = end; // set return address to last memory block
	end += size; // increment last memory block
	if (end > sector_base + SECTOR_SIZE) { // check if exceeded boundaries
		return_value = sector_base;
		end = sector_base + size; // the start of the sector
	}
	
	return return_value;
}
	
void free_last_gen(){
	start = end_old;
	end_old = end;
}

void initialize(){
	sector_base = sbrk(0); // returns address of the heap
	brk(sector_base + SECTOR_SIZE); // extends heap address space
	start = end_old = end = sector_base;
}

/* The following are K-d tree methods and definitions */

#define NULL ((void *)0)

struct Node {
   int x;
   int y;
   struct Node* left;
   struct Node* right;
};

struct Tree {
	unsigned size;
	struct Node* root;
};


struct Node* newNode(int x, int y){
	struct Node *n = allocate(sizeof(struct Node));
	n->y = y;
	n->x = x;
	n->left = NULL; 
	n->right = NULL;
	return n;
}


struct Tree* createTree(){
	struct Tree* temp = allocate(sizeof(struct Tree));
	temp->size = 0;
	temp->root = NULL;
	return temp;
}

// need translation
unsigned search(struct Tree *tree, int x, int y) {
	// 1 if found, zero otherwise
	
 	if(tree->size == 0) return 0;
 	struct Node* temp = tree->root;
 
 	unsigned depth = 0;   
	unsigned cd = 0; // cutting dimension starts with x
	do {
		if(temp->x == x && temp->y == y) return 1;
    	// if cutting dimension is x
    	if(cd==0){
    		// get movement direction 
    		if(temp->x < x){ // go left
    			if(!temp->left) return 0; // reached dead-end
    			else temp = temp->left;
    		}
    		
    		else { // go right
    			if(!temp->right) return 0;
    			else temp = temp->right;
    		}
		}
		// cutting dimension is y
		else{
			if(temp->y < y){ // go left
    			if(!temp->left) return 0;
    			   			
    			else temp = temp->left;
    		}	
    		else { // go right
    			if(!temp->right) return 0;	
    			else temp = temp->right;
    		}
		}
    depth++;
    cd = depth % 2; // flip cutting dimension
    } while(1);

}

// need translation
void insert(struct Tree *tree, int x, int y) {
    // (x, y) should not exist in tree
 	if(search(tree, x, y)) return;
 	
 	// if tree is empty
 	if(tree->size==0){
 		tree->root = newNode(x, y);
 		tree->size++;
 		return;
 	}
 	
 	struct Node* temp = tree->root;
 
 	unsigned depth = 0;   
	unsigned cd = 0; // cutting dimension starts with x
	do {
	
    	// if cutting dimension is x
    	if(cd==0){
    		// get movement direction 
    		if(temp->x < x){ // go left
    			if(!temp->left){
    				temp->left = newNode(x, y);
    				break;
    			}
    			   			
    			else temp = temp->left;
    		}
    		
    		else { // go right
    			if(!temp->right){
    				temp->right = newNode(x, y);
    				break;
    			}
    						
    			else temp = temp->right;
    		}
		}
		// cutting dimension is y
		else{
			if(temp->y < y){ // go left
    			if(!temp->left){
    				temp->left = newNode(x, y);
    				break;
    			}
    			   			
    			else temp = temp->left;
    		}	
    		else { // go right
    			if(!temp->right){
    				temp->right = newNode(x, y);
    				break;
    				}   			
    			else temp = temp->right;
    		}
		}
    depth++;
    cd = depth % 2; // flip cutting dimension
    } while(1);
	
	tree->size++;
}



 
/* The following are Queue methods */
struct QNode {
    struct Node* value;
    struct QNode* next;
};
 
// The queue, front stores the front node of LL and rear
// stores the last node of LL
struct Queue {
	unsigned size;
    struct QNode *front, *rear;
};
 
// A utility function to create a new linked list node.
struct QNode* newQNode(struct Node* value) {
    struct QNode* temp = allocate(sizeof(struct QNode));
    temp->value = value;
    temp->next = NULL;
    return temp;
}
 
// A utility function to create an empty queue
struct Queue* createQueue(struct Node* value) {
    struct Queue* q = allocate(sizeof(struct Queue));
	struct QNode* temp = newQNode(value);
    q->front = q->rear = temp;
    q->size=1;
    return q;
}
 
// The function to add a node to q
void enQueue(struct Queue* q, struct Node* value) {
    // Create a new LL node
    struct QNode* temp = newQNode(value);

 	// if queue is empty
 	if(q->size == 0) {
 		q->rear = q->front = temp;
 		q->size++;
 		return;
 	}
 	
    // Add the new node at the end of queue and change rear
    q->rear->next = temp;
    q->rear = temp;
    q->size++;
}
 
// Function to remove a key from given queue q
struct Node* deQueue(struct Queue* q) {
    // queue should not be empty
    // Store previous front and move front one node ahead
    struct QNode* temp = q->front;
 
    q->front = q->front->next;
	q->size--;
 	
 	struct Node* value = temp->value;
    
    return value;
}


/* The following is actual simulation code */

unsigned num_of_neighbors(struct Tree* tree, int x, int y){
	return search(tree, x - 1, y - 1) + search(tree, x - 1, y) + 
		   search(tree, x - 1, y + 1) + search(tree, x, y - 1) + 
		   search(tree, x, y + 1) + search(tree, x + 1, y - 1) + 
		   search(tree, x + 1, y) + search(tree, x + 1, y + 1);
}

// checks if node is alive based on conways rules
// returns 1 if alive, zero otherwise
unsigned is_alive(struct Tree* old_gen, int x, int y){
	unsigned num = num_of_neighbors(old_gen, x, y);
	unsigned was_alive = search(old_gen, x, y);
	return ((num == 3 || num == 2) && was_alive) || (num == 3 && !was_alive); 
}

// checks n and its neighbors and appends them to new_gen if they are alive
void process_node(struct Tree* old_gen, struct Tree* new_gen, struct Node* n){
	int x = n->x;
	int y = n->y;
	
	// check if self and neighbors should be added
	if(is_alive(old_gen, x - 1, y - 1)) insert(new_gen, x - 1, y - 1);
	if(is_alive(old_gen, x - 1, y)) insert(new_gen, x - 1, y);
	if(is_alive(old_gen, x - 1, y + 1)) insert(new_gen, x - 1, y + 1);
	if(is_alive(old_gen, x, y - 1)) insert(new_gen, x, y - 1);
	if(is_alive(old_gen, x, y)) insert(new_gen, x, y);
	if(is_alive(old_gen, x, y + 1)) insert(new_gen, x, y + 1);
	if(is_alive(old_gen, x + 1, y - 1)) insert(new_gen, x + 1, y - 1);
	if(is_alive(old_gen, x + 1, y)) insert(new_gen, x + 1, y);
	if(is_alive(old_gen, x + 1, y + 1)) insert(new_gen, x + 1, y + 1);
}

// applies my_func(Node*) to every node in the tree
// returns new tree node of the next generation
struct Tree* to_next_gen(struct Tree* old_gen){
	struct Queue* q = createQueue(old_gen->root);
	struct Tree* new_gen = createTree();
	struct Node* n;
	while(q->size != 0) { // while not empty
		n = deQueue(q); // take first node from queue

		// prepend its neighbors to queue
		if(n->left){
			enQueue(q, n->left);
		}
		if(n->right){
			enQueue(q, n->right);
		}		
		// apply function to node
		process_node(old_gen, new_gen, n);
		
	}
	
	return new_gen;
}

void print_num_to_file(unsigned num){
	// num will be treated as signed

	if (num & 0x80000000) { // check if negative (most significant bit is one) 
		write(file_descriptor, negative_sign_c, 1);
		num = ~num + 1; // twos complement
	
	}
	
	for(unsigned i = 0; i < 8; i++){
		// shift the most significant hex to the least significant
		unsigned offset = num >> 28; 
		write(file_descriptor, hex_characters + offset, 1);
		num = num << 4; // remove the most significant hex
	}
	
}

void printTreeToFile(struct Tree* tree){
	struct Queue* q = createQueue(tree->root);
	struct Node* n;

	write(file_descriptor, generation_c, 11);
	
	while(q->size != 0) { // while not empty
		n = deQueue(q); // take first node from queue
		// prepend its neighbors to queue
		if(n->left){
			enQueue(q, n->left);
		}
		if(n->right){
			enQueue(q, n->right);
		}
		
		// print one point 'x,y\n'
		print_num_to_file(n->x);
		write(file_descriptor, comma_c, 1);
		print_num_to_file(n->y);
		write(file_descriptor, new_line_c, 1);
		
	}
}


// driver code
int main(int argc, char* argv[]){
	initialize(); // init memory	

	unsigned num_of_gen = atoi(argv[1]);
	r = createTree();

	// creates file if it doesn't exist, opens in write mode, deletes any data at opening
	file_descriptor = open(filename, O_CREAT | O_WRONLY | O_TRUNC);

	// insert first generation
	insert(r, 0, 0);
	insert(r, 0, 1);
	insert(r, 0, -1);
	insert(r, 1, -1);
	insert(r, -1, 0);

	for(int i=0; i<num_of_gen; i++){
	
		printTreeToFile(r); // print last generation
		r = to_next_gen(r); // move to next gen
		free_last_gen(); // free the gen before it

	}
	
	close(file_descriptor);
	
	return 0;
}

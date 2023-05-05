import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys


def generation_points(file):

    line = file.readline()
    while line:
        # if new generation is reached then break
        if line.startswith("generation"):
            break

        # get x, y data of point
        x, y = line.split(',')
        # 16 means read in hexdecimal
        x = int(x.strip(), 16) 
        y = int(y.strip(), 16)

        yield x, y

        line = file.readline()


def generations_from_file(file):
    file.seek(0, 2)  # Jumps to the end
    end_location = file.tell()  # Give you the end location (characters from start)
    file.seek(0)  # Jump to the beginning of the file again
    # skip first line so that it doesn't conflict with line.startswith("generation")
    file.readline()

    while file.tell() != end_location:  # check if end of file reached
        arr = np.array([], dtype=int)
        # append generation points to numpy array
        for x, y in generation_points(file):
            arr = np.append(arr, [x, y])
        # reshape array to (x, y) pairs
        arr = arr.reshape((arr.shape[0]//2, 2))
        yield arr


def generations(file):
    for generation_data in generations_from_file(file):
        # get boundaries of simulation
        max_values = generation_data.max(axis=0)
        min_values = generation_data.min(axis=0)

        # increase boundaries by 5 elements for visual reasons
        max_values = max_values + 5
        min_values = min_values - 5

        # shift indices so that minimum is at zero
        # now all indices are positive
        generation_data = generation_data - min_values

        # length of true-false array, the 2d array will be a square for visual reasons
        length = (max_values - min_values).max()
        new_array = np.zeros((length, length))
        # set simulated points to true
        for point in generation_data:
            # points are inverted for display reasons
            new_array[point[1]][point[0]] = True
        yield new_array


def animate(i, generation_generator, ax):
    # so that it renders first frame
    if i == 0:
        return
    try:
        arr = generation_generator.__next__()
        print("generation", i)
    except StopIteration:
        input("Press Enter to exit... ")
        exit()

    ax.clear()
    plt.pcolormesh(arr)
    plt.axis('off')


if __name__ == '__main__':
    file = open('./simulation', 'r')

    # variables for animation wrapper
    fig = plt.figure()
    ax = fig.add_subplot(1, 1, 1)
    generator = generations(file)

    # animate is called every 'interval' milliseconds
    ani = animation.FuncAnimation(fig, lambda i: animate(i, generator, ax), interval=300)

    plt.show()
    
    file.close()
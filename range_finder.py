
import math

numbers = [i for i in range(1, 129)]
frame_size = 12
total_frames = math.ceil(len(numbers) / frame_size)


def rangeFinder(num):
    #example from 7 is in range 1 - 12
    #another example 20 is in range 12 - 24

    is_found = False

    frameIdx = 1
    
    for f in range(1, total_frames+1):
        try:
            frame_items = numbers[frameIdx-1:   f * frame_size]
            frameIdx = f * frame_size
        except IndexError:
            frame_items = numbers[frameIdx-1:   len(numbers)]

        is_found = num in frame_items
        
        if is_found: 
            print(f"{num} is found in {min(frame_items)} - {max(frame_items)}")
            break

    
    if not is_found:
        print("Index out of bounds exception")

        pass 


rangeFinder(20) #should return 12 - 24
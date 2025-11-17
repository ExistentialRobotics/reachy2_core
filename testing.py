from reachy2_sdk import ReachySDK

reachy = ReachySDK(host='localhost')
reachy.head.turn_on()

reachy.head.rotate_by(roll=0, pitch=30, yaw=0, frame='head')
reachy.head.rotate_by(roll=0, pitch=-50, yaw=0, frame='head')

reachy.turn_off_smoothly()
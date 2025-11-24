# picar_idm_controller.py
import json
import time
import ssl
import numpy as np
import paho.mqtt.client as mqtt
from picarx import Picarx
import vehicle_config as config
from datetime import datetime

class PiCarIDMController:
    def __init__(self, vehicle_id, aws_endpoint, cert_path):
        self.vehicle_id = vehicle_id
        self.px = Picarx()
        
        # Vehicle state (1D motion - only x position)
        self.x = 0.0        # Position along road (meters, lab scale)
        self.v = 14.0        # Velocity (m/s, lab scale)
        self.a = 0.0        # Acceleration (m/s², lab scale)
        self.a_old = 0.0    # Previous acceleration for smoothing
        
        # IDM parameters (lab scale)
        self.T = 1.5        # Time headway (seconds)
        self.a_max = 1.5    # Maximum acceleration (m/s²)
        self.b = 2.5        # Comfortable deceleration (m/s²)
        self.S0 = 2      # Minimum spacing: 2m real / 18 = 0.11m lab
        self.L = 4       # Vehicle length: 4m real / 18 = 0.22m lab
        self.Vd = 50/3.6       # Desired velocity: 50km/h real → 1.5 m/s lab (default)
        
        # Control parameters
        self.gamma = 0.35    # Smoothing factor for acceleration
        self.dt = 0.5       # Time step (10 Hz)
        
        # Trigger
        self.trigger_distance = 1000  # 300m real / 18
        self.trigger_sent = False
        self.intersection_x = 400    # Intersection position (lab scale)
        
        # MPC velocity profile
        self.velocity_profile = None
        self.profile_start_time = None
        self.profile_dt = 0.5
        self.iteration = 0
        self.start = 0
        
        # MQTT
        self.client = mqtt.Client(client_id=vehicle_id)
        self.client.on_connect = self.on_connect
        self.client.on_message = self.on_message
        
        self.client.tls_set(
            ca_certs=f"{cert_path}/AmazonRootCA1.pem",
            certfile=f"{cert_path}/{vehicle_id}_cert.pem",
            keyfile=f"{cert_path}/{vehicle_id}_private.key",
            tls_version=ssl.PROTOCOL_TLSv1_2
        )
        
        self.client.connect(aws_endpoint, 8883, 60)
        self.client.loop_start()
    
    def on_connect(self, client, userdata, flags, rc):
        print(f"✓ Connected to AWS IoT Core (rc={rc})")
        self.client.subscribe(f"vehicle/{self.vehicle_id}/command")
        print(f"✓ Subscribed to commands\n")
    
    def on_message(self, client, userdata, msg):
        """Receive velocity profile from MATLAB"""
        try:
            cmd = json.loads(msg.payload.decode())
            
            if cmd['command_type'] == 'velocity_profile':
                # Extract velocity profile
                profile_data = cmd['velocity_profile']
                self.velocity_profile = np.array(profile_data['values'])
                self.profile_dt = profile_data['dt']
                self.profile_start_time = time.time()
                
                traffic = cmd['traffic_light']
                
                print(f"\n{'='*60}")
                print(f"✓ VELOCITY PROFILE RECEIVED")
                print(f"{'='*60}")
                print(f"  Traffic: {traffic['state'].upper()} "
                      f"(green in {traffic['time_to_green']:.1f}s)")
                print(f"  Profile: {len(self.velocity_profile)} values "
                      f"over {len(self.velocity_profile)*self.profile_dt:.1f}s")
                print(f"  Vd range: {self.velocity_profile[0]:.3f} → "
                      f"{self.velocity_profile[-1]:.3f} m/s")
                print(f"{'='*60}\n")
                self.start = self.iteration
        
        except Exception as e:
            print(f"Error: {e}")
    
    def check_and_send_trigger(self):
        """Send trigger when reaching detection distance"""
        distance_to_intersection = self.intersection_x - self.x
        
        if self.x >= 100 and not self.trigger_sent:
            print(f"\n{'='*60}")
            print(f"🚨 TRIGGER POINT REACHED!")
            print(f"{'='*60}")
            print(f"  Position: x={self.x:.2f} m")
            print(f"  Distance to intersection: {distance_to_intersection:.2f} m")
            print(f"  Current velocity: {self.v:.3f} m/s")
            print(f"  Sending trigger to MATLAB...")
            
            trigger_msg = {
                "vehicle_id": self.vehicle_id,
                "timestamp": time.time(),
                "trigger_type": "intersection_approach",
                "position": {"x": self.x},
                "velocity": self.v,
                "distance_to_intersection": distance_to_intersection
            }
            
            topic = f"vehicle/{self.vehicle_id}/trigger"
            self.client.publish(topic, json.dumps(trigger_msg), qos=1)
            
            self.trigger_sent = True
            print(f"  ✓ Trigger sent!")
            print(f"{'='*60}\n")
    
    def get_desired_velocity(self):
        """Get desired velocity - from profile or default"""
        if self.velocity_profile is None:
            return self.Vd  # Default desired velocity
        
        # Get velocity from profile based on elapsed time
        elapsed = time.time() - self.profile_start_time
        index = int(elapsed / self.profile_dt)
        
        if index >= len(self.velocity_profile):
            # Profile finished, use last value
            return self.velocity_profile[-1]
        
        return self.velocity_profile[index]
    
    def IDM(self, Xh, Vh, Xp, Vp, Vd):
        """
        IDM function matching your MATLAB implementation
        
        Xh: Host vehicle position (this vehicle)
        Vh: Host vehicle velocity
        Xp: Preceding vehicle position (lead vehicle or intersection)
        Vp: Preceding vehicle velocity (0 for intersection)
        Vd: Desired velocity
        
        Returns: acceleration
        """
        # Gap to preceding vehicle
        dX = Xp - Xh - self.L
        
        # Desired gap
        Rd = self.S0 + (self.T * Vh) + Vh * (Vh - Vp) / (2 * np.sqrt(self.a_max * self.b))
        
        # IDM acceleration
        acc = self.a_max * (1 - (Vh / Vd)**4 - (Rd / dX)**2)
        
        return acc
    
    def compute_idm_acceleration(self):
        """
        Compute IDM acceleration
        Matches your MATLAB logic for intersection approach
        """
        # Get current desired velocity (from profile or default)
        Vd = self.get_desired_velocity()
        
        # Distance to intersection
        distance_to_intersection = self.intersection_x - self.x
        
        # Check if approaching intersection (within trigger range)
        if self.x > 100 and self.iteration - self.start <88:
        
            # Treating intersection as stopped vehicle
            # Position of "virtual stopped vehicle" at intersection + safety margin
            Xp = self.intersection_x  # 404.7 real / 18 / 48 ≈ 0.47 lab
            Vp = 0  # Stopped
            
            acc = self.IDM(self.x, self.v, Xp, Vp, Vd)
        else:
            # Free road - no preceding vehicle
            # Just use free acceleration term
            acc = self.IDM(self.x, self.v, self.x+100, 14, 50/3.6)
        
        return acc
    
    def update_vehicle_state(self):
        """
        Update vehicle state using IDM
        Matches your MATLAB update equations exactly
        """
        # Compute acceleration
        a_new = self.compute_idm_acceleration()
        
        # Apply smoothing (gamma filter)
        self.a = self.gamma * self.a_old + (1 - self.gamma) * a_new
        self.a_old = self.a
        
        # Clamp acceleration
        if self.a < -6:
            self.a = -6
        if self.a >= 2.5:
            self.a = 2.5
        
        # Update position and velocity (exact MATLAB equations)
        self.x = self.x + self.v * self.dt + 0.5 * self.a * (self.dt**2)
        self.v = self.v + self.a * self.dt
        
        # Velocity cannot be negative
        if self.v < 0:
            self.v = 0
        
        # Set motor based on velocity
        self.set_motor_from_velocity()
    
    def set_motor_from_velocity(self):
        """Convert velocity to motor PWM"""
        # Calibration: 0-2 m/s → 0-100 PWM
        # Adjust based on your motor calibration
        pwm = int((self.v / 2.0) * 100)
        pwm = max(0, min(100, pwm))
        
        if pwm > 10:  # Minimum PWM to overcome friction
            self.px.forward(pwm)
        else:
            self.px.stop()
    
    def run(self):
        """Main control loop - 10 Hz"""
        print(f"\n{'='*60}")
        print(f"🚗 {self.vehicle_id} Starting")
        print(f"{'='*60}")
        print(f"  Control: IDM (matching MATLAB implementation)")
        print(f"  Trigger distance: {self.trigger_distance} m")
        print(f"  Intersection at: x={self.intersection_x} m")
        print(f"  Initial Vd: {self.Vd:.3f} m/s")
        print(f"  Update frequency: {1/self.dt} Hz")
        print(f"{'='*60}\n")
        
        try:
            self.iteration = 0
            while True:
                # Check trigger point
                self.check_and_send_trigger()
                
                # Update vehicle state (IDM)
                self.update_vehicle_state()
                
                # Display status
                if self.iteration % 10 == 0:  # Every second
                    distance_to_int = self.intersection_x - self.x
                    Vd_current = self.get_desired_velocity()
                    
                    profile_status = ""
                    if self.velocity_profile is not None:
                        elapsed = time.time() - self.profile_start_time
                        index = int(elapsed / self.profile_dt)
                        if index < len(self.velocity_profile):
                            progress = (index / len(self.velocity_profile)) * 100
                            profile_status = f" [Profile {progress:.0f}%]"
                    
                    now_str = datetime.now().strftime("%H:%M:%S.%f")[:-3]  # e.g. 13:41:05.123
                    print(f"time={now_str} | iter={self.iteration:5d} | iter={self.start:5d} | "  f"x={self.x:6.2f}m | v={self.v:.3f}m/s | a={self.a:+.3f}m/s² | " f"Vd={Vd_current:.3f}m/s | dist={distance_to_int:5.2f}m{profile_status}")
                
                self.iteration += 1
                
                # Sleep to maintain 10 Hz
                time.sleep(self.dt)
                
        except KeyboardInterrupt:
            print("\n\nStopping...")
            self.px.stop()
            self.client.loop_stop()
            self.client.disconnect()

# Run
if __name__ == "__main__":
    import sys
    
    # Configuration
    vehicle_id = "picar_vehicle_1"
    aws_endpoint = "a8qm6pq22sdnt-ats.iot.us-east-1.amazonaws.com"
    cert_path = "/home/car1/pi/aws-certs"
    
    # Allow command line override of starting position
    if len(sys.argv) > 1:
        start_x = float(sys.argv[1])
        print(f"Starting position: x={start_x} m")
    
    vehicle = PiCarIDMController(vehicle_id, aws_endpoint, cert_path)
    
    # Optional: Set initial position if provided
    if len(sys.argv) > 1:
        vehicle.x = float(sys.argv[1])
    
    vehicle.run()
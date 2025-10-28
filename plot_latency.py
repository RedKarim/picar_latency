import pandas as pd
import matplotlib.pyplot as plt

def plot_latency():
    # Read the CSV files
    car2_data = pd.read_csv('car2_latency.csv')
    signal1_data = pd.read_csv('signal1_latency.csv')

    # Calculate and print statistics for car2_latency.csv
    car2_avg = car2_data['latency_ms'].mean()
    car2_max = car2_data['latency_ms'].max()
    car2_min = car2_data['latency_ms'].min()
    print("Car 2 Latency Statistics:")
    print(f"  Average: {car2_avg:.2f} ms")
    print(f"  Maximum: {car2_max:.2f} ms")
    print(f"  Minimum: {car2_min:.2f} ms")

    # Calculate and print statistics for signal1_latency.csv
    signal1_avg = signal1_data['latency_ms'].mean()
    signal1_max = signal1_data['latency_ms'].max()
    signal1_min = signal1_data['latency_ms'].min()
    print("\nSignal 1 Latency Statistics:")
    print(f"  Average: {signal1_avg:.2f} ms")
    print(f"  Maximum: {signal1_max:.2f} ms")
    print(f"  Minimum: {signal1_min:.2f} ms")

    # Convert timestamp to datetime objects
    car2_data['timestamp'] = pd.to_datetime(car2_data['timestamp'])
    signal1_data['timestamp'] = pd.to_datetime(signal1_data['timestamp'])

    # Plot car2_latency.csv
    plt.figure(figsize=(10, 6))
    plt.plot(car2_data['timestamp'], car2_data['latency_ms'], label='Car 2 Latency')
    plt.xlabel('Timestamp')
    plt.ylabel('Latency (ms)')
    plt.title('Car 2 Latency Over Time')
    plt.legend()
    plt.grid(True)
    plt.savefig('car2_latency.png')
    plt.close()

    # Plot signal1_latency.csv
    plt.figure(figsize=(10, 6))
    plt.plot(signal1_data['timestamp'], signal1_data['latency_ms'], label='Signal 1 Latency', color='orange')
    plt.xlabel('Timestamp')
    plt.ylabel('Latency (ms)')
    plt.title('Signal 1 Latency Over Time')
    plt.legend()
    plt.grid(True)
    plt.savefig('signal1_latency.png')
    plt.close()

    # Plot both on the same graph
    plt.figure(figsize=(10, 6))
    plt.plot(car2_data['timestamp'], car2_data['latency_ms'], label='Car 2 Latency')
    plt.plot(signal1_data['timestamp'], signal1_data['latency_ms'], label='Signal 1 Latency', color='orange')
    plt.xlabel('Timestamp')
    plt.ylabel('Latency (ms)')
    plt.title('Car 2 and Signal 1 Latency Over Time')
    plt.legend()
    plt.grid(True)
    plt.savefig('combined_latency.png')
    plt.close()

if __name__ == '__main__':
    plot_latency()
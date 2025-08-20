// frontend/src/App.tsx

import { ConnectWallet } from './components/ConnectWallet';
import { useAccount } from 'wagmi';

function App() {
  const { isConnected } = useAccount();

  return (
    // Main container with a light gray background and dark text
    <div className="bg-gray-50 text-gray-800 min-h-screen font-sans">
      
      {/* Header section with a white background, padding, and a bottom border */}
      <header className="bg-white p-4 flex justify-between items-center border-b border-gray-200 shadow-sm">
        <h1 className="text-2xl font-bold text-gray-900">
          The Architect DAO
        </h1>
        <ConnectWallet />
      </header>

      {/* Main content area */}
      <main className="p-8 max-w-7xl mx-auto">
        {isConnected ? (
          <div>
            {/* Your main dApp components will go here */}
            <h2 className="text-3xl font-semibold">Dashboard</h2>
            <p className="mt-2 text-gray-600">Welcome back to the platform!</p>
          </div>
        ) : (
          <div className="text-center mt-16">
            <h2 className="text-4xl font-bold mb-4">Welcome to the Decentralized Freelance Platform</h2>
            <p className="text-lg text-gray-600">Please connect your wallet to get started.</p>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;
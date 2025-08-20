// frontend/src/components/ConnectWallet.tsx
import { useState } from 'react';
import { useAccount, useConnect, useDisconnect } from 'wagmi';
import { type Connector } from 'wagmi';

export function ConnectWallet() {
  const [isModalOpen, setIsModalOpen] = useState(false);

  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();

  const handleWalletSelect = (connector: Connector) => {
    connect({ connector });
    setIsModalOpen(false);
  };

  const baseButtonStyles = "px-4 py-2 font-semibold text-white bg-blue-600 rounded-md hover:bg-blue-700 transition-colors";
  const connectedInfoStyles = "px-4 py-2 font-mono text-sm bg-gray-100 border border-gray-300 rounded-md";

  if (isConnected) {
    return (
      <div className="flex items-center gap-4">
        <span className={connectedInfoStyles}>
          {address?.slice(0, 6)}...{address?.slice(-4)}
        </span>
        <button onClick={() => disconnect()} className={baseButtonStyles}>
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <>
      <button onClick={() => setIsModalOpen(true)} className={baseButtonStyles}>
        Connect Wallet
      </button>

      {isModalOpen && (
        <div
          // --- UPDATED LINE ---
          className="blue fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm transition-opacity duration-300"
          onClick={() => setIsModalOpen(false)}
        >
          <div
            className="relative w-11/12 max-w-sm p-8 bg-white rounded-lg shadow-xl" // Added shadow-xl for better depth
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-bold text-gray-800">Select Wallet</h3>
              <button
                className="text-2xl text-gray-500 hover:text-gray-800"
                onClick={() => setIsModalOpen(false)}
              >
                &times;
              </button>
            </div>
            <div className="flex flex-col gap-4">
              {connectors.map((connector) => (
                <button
                  key={connector.uid}
                  onClick={() => handleWalletSelect(connector)}
                  className="w-full p-3 text-left border border-gray-300 rounded-md bg-gray-50 hover:bg-gray-100 transition-colors"
                >
                  {connector.name}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </>
  );
}
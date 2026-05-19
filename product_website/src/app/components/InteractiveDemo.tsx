import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Zap, Droplets, AlertCircle, CheckCircle } from 'lucide-react';

type SensorStatus = 'safe' | 'caution' | 'danger';

interface Scenario {
  id: string;
  title: string;
  description: string;
  phLevel: number;
  contamination: number;
  status: SensorStatus;
}

const scenarios: Scenario[] = [
  {
    id: 'fresh',
    title: 'Fresh Solution',
    description: 'Brand new solution, just changed today',
    phLevel: 7.2,
    contamination: 0,
    status: 'safe',
  },
  {
    id: 'aging',
    title: '3-Day Old Solution',
    description: 'Solution has been sitting for a few days',
    phLevel: 6.8,
    contamination: 35,
    status: 'caution',
  },
  {
    id: 'contaminated',
    title: 'Contaminated Case',
    description: 'Week-old solution with bacterial buildup',
    phLevel: 6.2,
    contamination: 85,
    status: 'danger',
  },
];

const statusConfig = {
  safe: {
    color: '#22C55E',
    label: 'Safe to Use',
    icon: CheckCircle,
    glow: 'rgba(34, 197, 94, 0.4)',
  },
  caution: {
    color: '#EAB308',
    label: 'Replace Soon',
    icon: AlertCircle,
    glow: 'rgba(234, 179, 8, 0.4)',
  },
  danger: {
    color: '#EF4444',
    label: 'Replace Now',
    icon: AlertCircle,
    glow: 'rgba(239, 68, 68, 0.4)',
  },
};

export function InteractiveDemo() {
  const [activeScenario, setActiveScenario] = useState<Scenario>(scenarios[0]);
  const [isScanning, setIsScanning] = useState(false);
  const [caseOpen, setCaseOpen] = useState(false);

  const handleScan = (scenario: Scenario) => {
    setIsScanning(true);
    setActiveScenario(scenario);
    setCaseOpen(true);

    // Simulate scanning animation
    setTimeout(() => {
      setIsScanning(false);
    }, 2000);
  };

  const statusInfo = statusConfig[activeScenario.status];
  const StatusIcon = statusInfo.icon;

  return (
    <div id="demo" className="min-h-screen bg-gradient-to-br from-primary/5 via-background to-accent/5 py-20">
      <div className="container mx-auto px-6">
        <div className="text-center mb-12">
          <motion.h2
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-4xl lg:text-5xl text-primary mb-4"
            style={{ fontWeight: 700 }}
          >
            Experience LensLife Intelligence
          </motion.h2>
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-xl text-primary/70 max-w-2xl mx-auto"
          >
            Try our interactive demo. Click a scenario to see real-time sensor analysis.
          </motion.p>
        </div>

        <div className="grid lg:grid-cols-2 gap-12 max-w-6xl mx-auto items-center">
          {/* Interactive Product Visualization */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="relative"
          >
            {/* Main Case Container */}
            <div className="bg-white/80 backdrop-blur-xl rounded-[32px] p-12 shadow-[0_20px_60px_rgba(30,58,95,0.15)] border border-white/60">
              {/* Contact Lens Case */}
              <div className="relative w-full max-w-md mx-auto aspect-square">
                {/* Case Body */}
                <motion.div
                  animate={{
                    rotateX: caseOpen ? -20 : 0,
                  }}
                  transition={{ duration: 0.6, ease: 'easeOut' }}
                  className="w-full h-full rounded-[28px] bg-gradient-to-br from-primary to-primary/80 shadow-2xl flex items-center justify-center relative overflow-hidden"
                  style={{ transformStyle: 'preserve-3d' }}
                >
                  {/* LED Indicator */}
                  <AnimatePresence mode="wait">
                    <motion.div
                      key={activeScenario.id}
                      initial={{ scale: 0, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      exit={{ scale: 0, opacity: 0 }}
                      className="absolute top-8 right-8 w-8 h-8 rounded-full"
                      style={{
                        backgroundColor: statusInfo.color,
                        boxShadow: `0 0 40px ${statusInfo.glow}, 0 0 80px ${statusInfo.glow}`,
                      }}
                    />
                  </AnimatePresence>

                  {/* Case Interior (visible when open) */}
                  <AnimatePresence>
                    {caseOpen && (
                      <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="absolute inset-0 flex items-center justify-center gap-8"
                      >
                        {/* Left Lens Well */}
                        <div className="w-24 h-24 rounded-full bg-white/20 backdrop-blur-sm border-2 border-white/40 flex items-center justify-center">
                          <div className="w-16 h-16 rounded-full bg-secondary/40" />
                        </div>

                        {/* Right Lens Well */}
                        <div className="w-24 h-24 rounded-full bg-white/20 backdrop-blur-sm border-2 border-white/40 flex items-center justify-center">
                          <div className="w-16 h-16 rounded-full bg-secondary/40" />
                        </div>
                      </motion.div>
                    )}
                  </AnimatePresence>

                  {/* Scanning Animation */}
                  {isScanning && (
                    <motion.div
                      initial={{ y: '-100%' }}
                      animate={{ y: '100%' }}
                      transition={{ duration: 2, ease: 'linear' }}
                      className="absolute inset-x-0 h-2 bg-gradient-to-r from-transparent via-accent to-transparent opacity-60"
                    />
                  )}
                </motion.div>

                {/* Status Badge */}
                <AnimatePresence mode="wait">
                  <motion.div
                    key={activeScenario.id}
                    initial={{ y: 20, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    exit={{ y: -20, opacity: 0 }}
                    className="absolute -bottom-6 left-1/2 -translate-x-1/2 px-6 py-3 rounded-[20px] backdrop-blur-xl border shadow-lg flex items-center gap-2 whitespace-nowrap"
                    style={{
                      backgroundColor: `${statusInfo.color}15`,
                      borderColor: statusInfo.color,
                      color: statusInfo.color,
                    }}
                  >
                    <StatusIcon className="w-5 h-5" />
                    <span style={{ fontWeight: 600 }}>{statusInfo.label}</span>
                  </motion.div>
                </AnimatePresence>
              </div>
            </div>
          </motion.div>

          {/* Sensor Readings & Controls */}
          <div className="space-y-6">
            {/* Current Readings */}
            <AnimatePresence mode="wait">
              <motion.div
                key={activeScenario.id}
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
                className="bg-white/80 backdrop-blur-xl rounded-[24px] p-6 shadow-lg border border-white/60"
              >
                <h3 className="text-xl text-primary mb-4" style={{ fontWeight: 600 }}>
                  Sensor Readings
                </h3>

                {/* pH Level */}
                <div className="mb-6">
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <Droplets className="w-5 h-5 text-accent" />
                      <span className="text-primary/80" style={{ fontWeight: 500 }}>pH Level</span>
                    </div>
                    <motion.span
                      key={activeScenario.phLevel}
                      initial={{ scale: 1.5, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      className="text-2xl text-primary"
                      style={{ fontWeight: 700 }}
                    >
                      {activeScenario.phLevel}
                    </motion.span>
                  </div>
                  <div className="h-2 bg-secondary/30 rounded-full overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${((activeScenario.phLevel - 6) / 1.5) * 100}%` }}
                      transition={{ duration: 0.8, ease: 'easeOut' }}
                      className="h-full bg-gradient-to-r from-accent to-secondary rounded-full"
                    />
                  </div>
                  <p className="text-xs text-primary/60 mt-1">Optimal: 7.0-7.4</p>
                </div>

                {/* Contamination Level */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center gap-2">
                      <Zap className="w-5 h-5 text-accent" />
                      <span className="text-primary/80" style={{ fontWeight: 500 }}>Contamination</span>
                    </div>
                    <motion.span
                      key={activeScenario.contamination}
                      initial={{ scale: 1.5, opacity: 0 }}
                      animate={{ scale: 1, opacity: 1 }}
                      className="text-2xl text-primary"
                      style={{ fontWeight: 700 }}
                    >
                      {activeScenario.contamination}%
                    </motion.span>
                  </div>
                  <div className="h-2 bg-secondary/30 rounded-full overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${activeScenario.contamination}%` }}
                      transition={{ duration: 0.8, ease: 'easeOut' }}
                      className="h-full rounded-full"
                      style={{
                        background: activeScenario.contamination > 70
                          ? 'linear-gradient(to right, #EF4444, #DC2626)'
                          : activeScenario.contamination > 30
                          ? 'linear-gradient(to right, #EAB308, #F59E0B)'
                          : 'linear-gradient(to right, #22C55E, #16A34A)',
                      }}
                    />
                  </div>
                  <p className="text-xs text-primary/60 mt-1">IR Spectroscopy</p>
                </div>
              </motion.div>
            </AnimatePresence>

            {/* Scenario Buttons */}
            <div className="space-y-3">
              <p className="text-sm text-primary/60 mb-3" style={{ fontWeight: 500 }}>
                Try Different Scenarios:
              </p>
              {scenarios.map((scenario) => (
                <motion.button
                  key={scenario.id}
                  onClick={() => handleScan(scenario)}
                  disabled={isScanning}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  className={`w-full text-left p-4 rounded-[20px] border-2 transition-all ${
                    activeScenario.id === scenario.id
                      ? 'bg-accent/10 border-accent shadow-lg'
                      : 'bg-white/60 backdrop-blur-sm border-white/60 hover:border-accent/50'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div>
                      <h4 className="text-primary mb-1" style={{ fontWeight: 600 }}>
                        {scenario.title}
                      </h4>
                      <p className="text-sm text-primary/60">{scenario.description}</p>
                    </div>
                    <div
                      className="w-6 h-6 rounded-full flex-shrink-0"
                      style={{ backgroundColor: statusConfig[scenario.status].color }}
                    />
                  </div>
                </motion.button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

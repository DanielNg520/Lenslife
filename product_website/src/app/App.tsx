import { ShoppingCart, Zap, Shield, AlertCircle, Menu } from 'lucide-react';
import { useState } from 'react';
import { Logo } from './components/Logo';
import { InteractiveDemo } from './components/InteractiveDemo';

export default function App() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const scrollToSection = (id: string) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
      setMobileMenuOpen(false);
    }
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Sticky Navigation */}
      <nav className="sticky top-0 z-50 bg-white/95 backdrop-blur-sm shadow-[0_4px_24px_rgba(45,106,106,0.08)]">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <Logo className="h-10" />

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center gap-8">
              <button
                onClick={() => scrollToSection('hero')}
                className="text-primary/70 hover:text-primary transition-colors"
                style={{ fontWeight: 500 }}
              >
                Home
              </button>
              <button
                onClick={() => scrollToSection('demo')}
                className="text-primary/70 hover:text-primary transition-colors"
                style={{ fontWeight: 500 }}
              >
                Demo
              </button>
              <button
                onClick={() => scrollToSection('about')}
                className="text-primary/70 hover:text-primary transition-colors"
                style={{ fontWeight: 500 }}
              >
                About
              </button>
              <button
                onClick={() => scrollToSection('technology')}
                className="text-primary/70 hover:text-primary transition-colors"
                style={{ fontWeight: 500 }}
              >
                Technology
              </button>
              <button
                onClick={() => scrollToSection('how-it-works')}
                className="text-primary/70 hover:text-primary transition-colors"
                style={{ fontWeight: 500 }}
              >
                How It Works
              </button>
              <button
                onClick={() => scrollToSection('pricing')}
                className="px-6 py-2 bg-accent text-white rounded-[20px] hover:shadow-[0_8px_24px_rgba(90,161,214,0.4)] transition-all"
                style={{ fontWeight: 600 }}
              >
                Buy Now
              </button>
            </div>

            {/* Mobile Menu Button */}
            <button
              className="md:hidden text-primary"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            >
              <Menu className="w-6 h-6" />
            </button>
          </div>

          {/* Mobile Menu */}
          {mobileMenuOpen && (
            <div className="md:hidden mt-4 pt-4 border-t border-primary/10 space-y-3">
              <button
                onClick={() => scrollToSection('hero')}
                className="block w-full text-left text-primary/70 hover:text-primary transition-colors py-2"
                style={{ fontWeight: 500 }}
              >
                Home
              </button>
              <button
                onClick={() => scrollToSection('demo')}
                className="block w-full text-left text-primary/70 hover:text-primary transition-colors py-2"
                style={{ fontWeight: 500 }}
              >
                Demo
              </button>
              <button
                onClick={() => scrollToSection('about')}
                className="block w-full text-left text-primary/70 hover:text-primary transition-colors py-2"
                style={{ fontWeight: 500 }}
              >
                About
              </button>
              <button
                onClick={() => scrollToSection('technology')}
                className="block w-full text-left text-primary/70 hover:text-primary transition-colors py-2"
                style={{ fontWeight: 500 }}
              >
                Technology
              </button>
              <button
                onClick={() => scrollToSection('how-it-works')}
                className="block w-full text-left text-primary/70 hover:text-primary transition-colors py-2"
                style={{ fontWeight: 500 }}
              >
                How It Works
              </button>
              <button
                onClick={() => scrollToSection('pricing')}
                className="px-6 py-2 bg-accent text-white rounded-[20px] w-full"
                style={{ fontWeight: 600 }}
              >
                Buy Now
              </button>
            </div>
          )}
        </div>
      </nav>
      {/* Hero Section */}
      <section id="hero" className="container mx-auto px-6 py-16 lg:py-24">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          {/* Left: Logo and CTA */}
          <div className="space-y-8">
            <div className="space-y-6">
              <Logo className="h-20 lg:h-24" />

              <h2 className="text-4xl lg:text-5xl text-primary" style={{ fontWeight: 600 }}>
                See clearly, live safely.
              </h2>

              <p className="text-xl text-primary/80 max-w-md">
                The first smart contact lens case that uses science to protect your eyes from contamination and pH imbalance.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row gap-4">
              <button
                onClick={() => scrollToSection('demo')}
                className="px-8 py-4 bg-accent text-white rounded-[24px] shadow-[0_8px_24px_rgba(90,161,214,0.3)] hover:shadow-[0_12px_32px_rgba(90,161,214,0.4)] transition-all duration-300 hover:scale-105"
                style={{ fontWeight: 600, fontSize: '1.125rem' }}
              >
                Try Interactive Demo →
              </button>
              <button
                onClick={() => scrollToSection('pricing')}
                className="px-8 py-4 bg-white text-primary border-2 border-primary/20 rounded-[24px] hover:border-accent hover:bg-accent/5 transition-all duration-300"
                style={{ fontWeight: 600, fontSize: '1.125rem' }}
              >
                Buy Now - $39.99
              </button>
            </div>
          </div>

          {/* Right: Product Image Placeholder */}
          <div className="relative">
            <div className="bg-white rounded-[32px] shadow-[0_16px_48px_rgba(45,106,106,0.15)] p-12 flex items-center justify-center">
              <div className="w-full max-w-md mx-auto aspect-square bg-gradient-to-br from-secondary/20 to-primary/10 rounded-[24px] flex items-center justify-center">
                <p className="text-primary/40 text-center px-8" style={{ fontWeight: 500 }}>
                  Product Image
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Interactive Demo Section */}
      <InteractiveDemo />

      {/* About Section */}
      <section id="about" className="bg-white/50 py-20">
        <div className="container mx-auto px-6">
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-4xl text-primary mb-6" style={{ fontWeight: 700 }}>
              About LensLife
            </h2>
            <p className="text-xl text-primary/80 leading-relaxed mb-8">
              LensLife smart contact lens case that combines sensor technology with elegant design.
            </p>
            <p className="text-lg text-primary/70 leading-relaxed">
              Our mission is simple—make lens care as smart as the devices you already trust. With LensLife, guessing is replaced by real-time data, and worry is replaced by confidence.
            </p>
          </div>
        </div>
      </section>

      {/* The Problem: Guesswork vs. Science */}
      <section className="bg-background py-20">
        <div className="container mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-4xl text-primary mb-4" style={{ fontWeight: 700 }}>
              Guesswork vs. Science
            </h2>
            <p className="text-xl text-primary/70 max-w-2xl mx-auto">
              Stop risking your eye health with traditional cases. LensLife brings precision to lens care.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto">
            {/* Old Way Card */}
            <div className="bg-gradient-to-br from-red-50 to-orange-50 rounded-[28px] p-8 shadow-[0_8px_32px_rgba(0,0,0,0.08)] border border-red-100">
              <div className="flex items-start gap-4 mb-6">
                <div className="w-12 h-12 bg-red-100 rounded-full flex items-center justify-center flex-shrink-0">
                  <AlertCircle className="w-6 h-6 text-red-600" />
                </div>
                <div>
                  <h3 className="text-2xl text-red-900 mb-2" style={{ fontWeight: 600 }}>
                    Traditional Cases
                  </h3>
                  <p className="text-red-700/80">The old way</p>
                </div>
              </div>

              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <span className="text-red-500 mt-1">✗</span>
                  <span className="text-red-900/80">No way to detect bacterial contamination</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-500 mt-1">✗</span>
                  <span className="text-red-900/80">Guessing when to change solution</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-500 mt-1">✗</span>
                  <span className="text-red-900/80">Risk of serious eye infections</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-500 mt-1">✗</span>
                  <span className="text-red-900/80">pH levels unknown and unmonitored</span>
                </li>
              </ul>
            </div>

            {/* LensLife Card */}
            <div className="bg-gradient-to-br from-blue-50 to-secondary/30 rounded-[28px] p-8 shadow-[0_8px_32px_rgba(30,58,95,0.15)] border border-secondary">
              <div className="flex items-start gap-4 mb-6">
                <div className="w-12 h-12 bg-secondary rounded-full flex items-center justify-center flex-shrink-0">
                  <Shield className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h3 className="text-2xl text-primary mb-2" style={{ fontWeight: 600 }}>
                    LensLife Smart Case
                  </h3>
                  <p className="text-primary/70">Data-backed protection</p>
                </div>
              </div>

              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <span className="text-green-600 mt-1">✓</span>
                  <span className="text-primary/90">Real-time IR contamination scanning</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-green-600 mt-1">✓</span>
                  <span className="text-primary/90">Precision pH electrode monitoring</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-green-600 mt-1">✓</span>
                  <span className="text-primary/90">Instant LED alerts for safety</span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-green-600 mt-1">✓</span>
                  <span className="text-primary/90">Data-backed insights for peace of mind</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* The Tech Section */}
      <section id="technology" className="py-20">
        <div className="container mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-4xl text-primary mb-4" style={{ fontWeight: 700 }}>
              Inside the Intelligence
            </h2>
            <p className="text-xl text-primary/70 max-w-2xl mx-auto">
              Two powerful sensors work together to keep your lenses safe and your eyes healthy.
            </p>
          </div>

          <div className="max-w-4xl mx-auto bg-white rounded-[32px] shadow-[0_16px_48px_rgba(45,106,106,0.12)] p-12">
            <div className="grid md:grid-cols-2 gap-12 items-center">
              <div className="relative">
                <div className="w-full aspect-square bg-gradient-to-br from-primary/10 to-secondary/20 rounded-[24px] flex items-center justify-center">
                  <p className="text-primary/40 text-center px-8" style={{ fontWeight: 500 }}>
                    Technical Diagram
                  </p>
                </div>

                {/* Callout Lines */}
                <div className="absolute top-1/4 -right-4 w-24 h-0.5 bg-primary/30 hidden md:block"></div>
                <div className="absolute bottom-1/4 -right-4 w-24 h-0.5 bg-primary/30 hidden md:block"></div>
              </div>

              <div className="space-y-8">
                <div className="space-y-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-accent/20 rounded-full flex items-center justify-center">
                      <Zap className="w-5 h-5 text-accent" />
                    </div>
                    <h3 className="text-2xl text-primary" style={{ fontWeight: 600 }}>
                      IR Contamination Scanner
                    </h3>
                  </div>
                  <p className="text-primary/70 pl-13">
                    Advanced infrared technology detects bacterial presence and biofilm buildup before they become dangerous. Real-time analysis every time you open the case.
                  </p>
                </div>

                <div className="space-y-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-secondary/40 rounded-full flex items-center justify-center">
                      <Shield className="w-5 h-5 text-primary" />
                    </div>
                    <h3 className="text-2xl text-primary" style={{ fontWeight: 600 }}>
                      Precision pH Electrode
                    </h3>
                  </div>
                  <p className="text-primary/70 pl-13">
                    Medical-grade pH sensing ensures your solution maintains the optimal 7.0-7.4 range. Get instant warnings when it's time to refresh your solution.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Status Guide */}
      <section id="how-it-works" className="bg-white/50 py-20">
        <div className="container mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-4xl text-primary mb-4" style={{ fontWeight: 700 }}>
              Simple LED Status Guide
            </h2>
            <p className="text-xl text-primary/70 max-w-2xl mx-auto">
              One glance tells you everything you need to know.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
            {/* Green - Safe */}
            <div className="bg-white rounded-[24px] p-8 shadow-[0_8px_24px_rgba(45,106,106,0.1)] text-center hover:shadow-[0_12px_32px_rgba(45,106,106,0.15)] transition-shadow duration-300">
              <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6 shadow-[0_0_32px_rgba(34,197,94,0.3)]">
                <div className="w-12 h-12 bg-green-500 rounded-full"></div>
              </div>
              <h3 className="text-2xl text-primary mb-3" style={{ fontWeight: 600 }}>
                Green - Safe
              </h3>
              <p className="text-primary/70">
                Everything is perfect. Your lenses are safe to wear.
              </p>
            </div>

            {/* Yellow - Caution */}
            <div className="bg-white rounded-[24px] p-8 shadow-[0_8px_24px_rgba(45,106,106,0.1)] text-center hover:shadow-[0_12px_32px_rgba(45,106,106,0.15)] transition-shadow duration-300">
              <div className="w-20 h-20 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-6 shadow-[0_0_32px_rgba(234,179,8,0.3)]">
                <div className="w-12 h-12 bg-yellow-500 rounded-full"></div>
              </div>
              <h3 className="text-2xl text-primary mb-3" style={{ fontWeight: 600 }}>
                Yellow - Caution
              </h3>
              <p className="text-primary/70">
                Solution pH is borderline. Consider changing it soon.
              </p>
            </div>

            {/* Orange - Change Solution */}
            <div className="bg-white rounded-[24px] p-8 shadow-[0_8px_24px_rgba(45,106,106,0.1)] text-center hover:shadow-[0_12px_32px_rgba(45,106,106,0.15)] transition-shadow duration-300">
              <div className="w-20 h-20 bg-orange-100 rounded-full flex items-center justify-center mx-auto mb-6 shadow-[0_0_32px_rgba(255,179,138,0.4)]">
                <div className="w-12 h-12 bg-[#FFB38A] rounded-full"></div>
              </div>
              <h3 className="text-2xl text-primary mb-3" style={{ fontWeight: 600 }}>
                Orange - Change
              </h3>
              <p className="text-primary/70">
                Replace solution now. Contamination or pH issue detected.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Product/Pricing */}
      <section id="pricing" className="py-20">
        <div className="container mx-auto px-6">
          <div className="max-w-2xl mx-auto">
            <div className="bg-white rounded-[32px] shadow-[0_20px_60px_rgba(45,106,106,0.2)] overflow-hidden">
              {/* Product Image Placeholder */}
              <div className="bg-gradient-to-br from-secondary/20 to-primary/5 p-12 flex items-center justify-center">
                <div className="w-full max-w-sm mx-auto aspect-square bg-white/50 rounded-[24px] flex items-center justify-center">
                  <p className="text-primary/40 text-center px-8" style={{ fontWeight: 500 }}>
                    Product Kit Image
                  </p>
                </div>
              </div>

              {/* Product Details */}
              <div className="p-10 space-y-6">
                <div>
                  <h3 className="text-3xl text-primary mb-2" style={{ fontWeight: 700 }}>
                    LensLife Starter Kit
                  </h3>
                  <p className="text-primary/70">
                    Everything you need for smarter, safer lens care
                  </p>
                </div>

                <div className="space-y-3">
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-secondary rounded-full"></div>
                    <span className="text-primary/80">1× LensLife Smart Case with dual sensors</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-secondary rounded-full"></div>
                    <span className="text-primary/80">USB-C charging cable (30-day battery life)</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-secondary rounded-full"></div>
                    <span className="text-primary/80">Quick start guide & care instructions</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-2 h-2 bg-secondary rounded-full"></div>
                    <span className="text-primary/80">2-year warranty & lifetime support</span>
                  </div>
                </div>

                <div className="border-t border-primary/10 pt-6 flex items-end justify-between">
                  <div>
                    <p className="text-primary/60 mb-1">Starting at</p>
                    <p className="text-5xl text-primary" style={{ fontWeight: 700 }}>
                      $39<span className="text-2xl">.99</span>
                    </p>
                  </div>

                  <button
                    className="px-8 py-4 bg-accent text-white rounded-[24px] shadow-[0_8px_24px_rgba(90,161,214,0.3)] hover:shadow-[0_12px_32px_rgba(90,161,214,0.4)] transition-all duration-300 hover:scale-105 flex items-center gap-3"
                    style={{ fontWeight: 600, fontSize: '1.125rem' }}
                  >
                    <ShoppingCart className="w-5 h-5" />
                    Add to Cart
                  </button>
                </div>
              </div>
            </div>

            {/* Trust Badges */}
            <div className="mt-8 flex items-center justify-center gap-8 text-primary/60">
              <div className="flex items-center gap-2">
                <Shield className="w-5 h-5" />
                <span>2-Year Warranty</span>
              </div>
              <div className="h-6 w-px bg-primary/20"></div>
              <div className="flex items-center gap-2">
                <span>Free Shipping</span>
              </div>
              <div className="h-6 w-px bg-primary/20"></div>
              <div className="flex items-center gap-2">
                <span>30-Day Returns</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-primary text-primary-foreground py-12">
        <div className="container mx-auto px-6 text-center">
          <div className="flex justify-center mb-6">
            <Logo className="h-14" variant="white" />
          </div>
          <p className="text-primary-foreground/80 mb-6">
            See clearly, live safely.
          </p>
          <p className="text-sm text-primary-foreground/60">
            © 2026 LensLife. Designed for your eye health.
          </p>
        </div>
      </footer>
    </div>
  );
}

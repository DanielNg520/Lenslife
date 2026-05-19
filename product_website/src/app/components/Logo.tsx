// interface LogoProps {
//   className?: string;
//   showText?: boolean;
//   variant?: 'default' | 'white';
// }

// export function Logo({ className = "", showText = true, variant = 'default' }: LogoProps) {
//   const isWhite = variant === 'white';

//   return (
//     <div className={`flex items-center gap-3 ${className}`}>
//       <svg
//         width="48"
//         height="34"
//         viewBox="0 0 80 56"
//         fill="none"
//         xmlns="http://www.w3.org/2000/svg"
//         className="flex-shrink-0"
//       >
//         {/* Outer eye shape */}
//         <path
//           d="M40 4C22 4 6 22 2 28C6 34 22 52 40 52C58 52 74 34 78 28C74 22 58 4 40 4Z"
//           stroke={isWhite ? "white" : "#7EC8E3"}
//           strokeWidth="3.5"
//           fill={isWhite ? "rgba(255,255,255,0.05)" : "#EBF6FB"}
//           strokeLinecap="round"
//           strokeLinejoin="round"
//         />
//         {/* Wing accent left */}
//         <path
//           d="M8 28C14 22 22 14 32 11"
//           stroke={isWhite ? "rgba(255,255,255,0.4)" : "#A8DCF0"}
//           strokeWidth="2"
//           fill="none"
//           strokeLinecap="round"
//         />
//         {/* Wing accent right */}
//         <path
//           d="M72 28C66 22 58 14 48 11"
//           stroke={isWhite ? "rgba(255,255,255,0.4)" : "#A8DCF0"}
//           strokeWidth="2"
//           fill="none"
//           strokeLinecap="round"
//         />
//         {/* Outer iris ring - light blue */}
//         <circle
//           cx="40"
//           cy="28"
//           r="18"
//           stroke={isWhite ? "rgba(255,255,255,0.7)" : "#7EC8E3"}
//           strokeWidth="3"
//           fill={isWhite ? "rgba(255,255,255,0.1)" : "#D6EEF8"}
//         />
//         {/* Middle iris ring - teal */}
//         <circle
//           cx="40"
//           cy="28"
//           r="13"
//           stroke={isWhite ? "rgba(255,255,255,0.85)" : "#3DBCCC"}
//           strokeWidth="3"
//           fill={isWhite ? "rgba(255,255,255,0.15)" : "#C2EBF0"}
//         />
//         {/* Inner iris ring - deeper teal */}
//         <circle
//           cx="40"
//           cy="28"
//           r="8.5"
//           stroke={isWhite ? "rgba(255,255,255,0.9)" : "#1E8FA0"}
//           strokeWidth="2"
//           fill={isWhite ? "rgba(255,255,255,0.2)" : "#A0D8E0"}
//         />
//         {/* Pupil */}
//         <circle
//           cx="40"
//           cy="28"
//           r="5"
//           fill={isWhite ? "white" : "#1A3A6B"}
//         />
//         {/* Highlight */}
//         <circle
//           cx="42"
//           cy="26"
//           r="1.8"
//           fill={isWhite ? "#1A3A6B" : "white"}
//           opacity="0.9"
//         />
//       </svg>

//       {showText && (
//         <span
//           className={isWhite ? "text-white" : "text-[#1A2F4E]"}
//           style={{ fontWeight: 600, letterSpacing: '-0.02em', fontSize: '1.4rem' }}
//         >
//           LensLife
//         </span>
//       )}
//     </div>
//   );
// }

import logoImg from '@/imports/logo.png'

interface LogoProps {
  className?: string;
  variant?: 'default' | 'white';
}

export function Logo({ className = "" }: LogoProps) {
  return (
    <div className={`flex items-center ${className}`}>
      {/* <img src={logoImg} alt="LensLife" className="h-14 w-auto flex-shrink-0" /> */}
      <img src={logoImg} alt="LensLife" className={`h-24 w-auto flex-shrink-0 ${className}`} />
    </div>
  );
}
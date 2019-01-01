  function updateHolographicBackground(value) {
    const percentage = value * 100;
    document.body.style.backgroundPosition = percentage + "%";
  }

  function handleMouseMove(event) {
    const x = event.clientX;
    const width = document.documentElement.clientWidth;
    const value = x / width;
    updateHolographicBackground(value);
  }


  window.addEventListener("deviceorientation", handleOrientation, true);

function handleOrientation(event) {
          const z = event.gamma; // rotation degrees from 0 to 360
          document.body.style.backgroundPosition = scale(z, -90, 90, 0, 100) + "%";
  }

  const scale = (num, in_min, in_max, out_min, out_max) => {
  return (num - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

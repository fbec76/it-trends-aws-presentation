import "./App.css";

import React from "react";
import logo from "./logo.svg";
import { url } from "inspector";

function App() {
  const [count, setCount] = React.useState(0);

  return (
    <div className="App">
      <header className="App-header">
        <img
          src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/0e/Hochschule_für_Oekonomie_%26_Management_2012_logo.svg/1920px-Hochschule_für_Oekonomie_%26_Management_2012_logo.svg.png"
          className="App-logo"
          alt="logo"
        />

        <h1>FOM IT Trends 2023</h1>
        <button
          onClick={() => {
            setCount(count + 1);
          }}
          style={{ fontSize: "2rem" }}
        >
          click me!
        </button>
        <p>count: {count}</p>
        <p>
          Am I deployed to the cloud?{" "}
          {window.document.URL.includes("localhost") ? "No" : "Yes"}
        </p>
      </header>
    </div>
  );
}

export default App;

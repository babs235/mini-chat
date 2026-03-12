const API = "http://localhost:3000";

async function register() {

const username = document.getElementById("registerUsername").value;
const password = document.getElementById("registerPassword").value;

const res = await fetch(API + "/auth/register", {

method: "POST",

headers: {
"Content-Type": "application/json"
},

body: JSON.stringify({ username, password })

});

const data = await res.json();

alert(data.message);

}

async function login() {

const username = document.getElementById("loginUsername").value;
const password = document.getElementById("loginPassword").value;

const res = await fetch(API + "/auth/login", {

method: "POST",

headers: {
"Content-Type": "application/json"
},

body: JSON.stringify({ username, password })

});

const data = await res.json();

if(data.userId){

localStorage.setItem("userId", data.userId);
localStorage.setItem("username", data.username);

window.location.href = "messages.html";

}else{

alert("Connexion échouée");

}

}
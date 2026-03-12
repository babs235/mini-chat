const API = "http://localhost:3000";

const userId = localStorage.getItem("userId");
const username = localStorage.getItem("username");

if(!userId){
window.location.href = "index.html";
}

document.getElementById("welcome").innerText = "Connecté en tant que : " + username;


async function loadMessages(){

const res = await fetch(API + "/messages");

const data = await res.json();

const list = document.getElementById("messages");

list.innerHTML = "";

data.forEach(msg => {

const li = document.createElement("li");

li.textContent = msg.username + " : " + msg.message;

list.appendChild(li);

});

}


async function sendMessage(){

const message = document.getElementById("messageInput").value;

await fetch(API + "/messages",{

method:"POST",

headers:{
"Content-Type":"application/json"
},

body:JSON.stringify({
user_id:userId,
message:message
})

});

document.getElementById("messageInput").value="";

loadMessages();

}


function logout(){

localStorage.removeItem("userId");
localStorage.removeItem("username");

window.location.href = "index.html";

}


loadMessages();

setInterval(loadMessages,3000);
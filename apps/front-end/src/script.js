const connection = new signalR.HubConnectionBuilder()
      .withUrl("https://localhost:44351/connection")
      .withAutomaticReconnect()
      .build();

async function startSignalR() {
    try {
        await connection.start();
        console.log("SignalR Conectado! ID da Conexão: " + connection.connectionId);
    } catch (err) {
        console.error("Falha ao conectar com o SignalR", err);
        setTimeout(startSignalR, 5000);
    }
}

startSignalR();

document.getElementById("uploadBtn").addEventListener("click", async () => {
  const fileInput = document.getElementById("fileInput");
  const status = document.getElementById("status");

  if (fileInput.files.length === 0) {
    status.textContent = "Selecione um arquivo primeiro!";
    status.style.color = "red";
    return;
  }

   if (connection.state === "Connected") {
        const file = fileInput.files[0];
        const formData = new FormData();
        formData.append("file", file);

  try {
    status.textContent = "Enviando...";
    status.style.color = "black";

    const myHeaders = new Headers();
    myHeaders.append("X-Connection-Id", connection.connectionId);
    const response = await fetch("https://localhost:44351/PostImageBlob", {
      method: "POST",
      body: formData,
      headers: myHeaders
    });

    if (response.ok) {
      status.textContent = "Upload concluído!";
      status.style.color = "green";
    } else {
      status.textContent = "Erro no upload!";
      status.style.color = "red";
    }
  } catch (err) {
    console.error(err);
    status.textContent = "Erro de conexão!";
    status.style.color = "red";
  }
    } else {
        status.textContent = "SignalR não está conectado.";
        status.style.color = "red";
    }
});

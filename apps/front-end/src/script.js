document.getElementById("uploadBtn").addEventListener("click", async () => {
  const fileInput = document.getElementById("fileInput");
  const status = document.getElementById("status");

  if (fileInput.files.length === 0) {
    status.textContent = "Selecione um arquivo primeiro!";
    status.style.color = "red";
    return;
  }

  const file = fileInput.files[0];
  const formData = new FormData();
  formData.append("file", file);

  try {
    status.textContent = "Enviando...";
    status.style.color = "black";

    const response = await fetch("https://localhost:44351/PostImageS3", {
      method: "POST",
      body: formData
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
});

import React, { useState } from 'react';
import axios from 'axios';
import './App.css'; // Adicione esta linha para importar o CSS

function App() {
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState('');

  const handleFileChange = (event) => {
    const selectedFile = event.target.files[0];
    if (selectedFile && selectedFile.name.toLowerCase().endsWith('.zip')) {
      setFile(selectedFile);
      setMessage('');
    } else {
      setMessage('Por favor, selecione um arquivo ZIP.');
      setFile(null);
    }
  };

  const handleUpload = async () => {
    if (!file) return;

    setUploading(true);
    setMessage('');

    try {
      const response = await axios.get('http://localhost:3001/generate-presigned-url', {
        params: {
          filename: file.name,
          filetype: file.type
        }
      });

      const { url } = response.data;

      await axios.put(url, file, {
        headers: {
          'Content-Type': file.type
        }
      });

      setMessage('Upload realizado com sucesso!');
    } catch (error) {
      console.error('Erro ao fazer upload:', error);
      setMessage('Erro ao fazer upload');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="App">
      <h1>Upload de Arquivo para S3</h1>
      <input type="file" onChange={handleFileChange} />
      <button onClick={handleUpload} disabled={!file || uploading}>
        {uploading ? 'Carregando...' : 'Upload'}
      </button>
      {message && <p>{message}</p>}
    </div>
  );
}

export default App;
class GuestBookApp {
    constructor() {
        this.apiUrl = '';
        this.frontendVersion = '1.0.3';
        this.init();
    }

    async init() {
        document.getElementById('frontend-version').textContent = this.frontendVersion;
        await this.loadAppInfo();
        await this.loadMessages();
        this.setupEventListeners();
    }

    async loadAppInfo() {
        try {
            const response = await fetch('/api/stats');
            const data = await response.json();

            document.getElementById('backend-version').textContent =
                data.backend_version || 'unknown';

            document.getElementById('total-messages').textContent =
                data.total_messages || 0;

            const versionResponse = await fetch('/api/version');
            const versionData = await versionResponse.json();

            if (versionData.container) {
                document.getElementById('container-id').textContent =
                    versionData.container.substring(0, 12) + '...';
            }
        } catch (error) {
            console.error('Ошибка загрузки информации:', error);
            document.getElementById('backend-version').textContent = 'Ошибка';
        }
    }

    async loadMessages() {
        try {
            const response = await fetch('/api/messages');
            const messages = await response.json();

            if (Array.isArray(messages)) {
                this.displayMessages(messages);
            }
        } catch (error) {
            console.error('Ошибка загрузки сообщений:', error);
        }
    }

    displayMessages(messages) {
        const container = document.getElementById('messages-container');

        if (messages.length === 0) {
            container.innerHTML = '<p>Пока нет сообщений</p>';
            return;
        }

        container.innerHTML = messages.map(msg => `
            <div class="message-item">
                <div class="message-header">
                    <span class="message-author">${msg.author || 'Аноним'}</span>
                    <span class="message-time">
                        ${new Date(msg.created_at).toLocaleString('ru-RU')}
                    </span>
                </div>
                <div class="message-text">${msg.message}</div>
            </div>
        `).join('');
    }

    async addMessage(author, message) {
        try {
            const response = await fetch('/api/messages', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    author: author || 'Аноним',
                    message
                })
            });

            const result = await response.json();
            if (result.error) throw new Error(result.error);

            alert('Сообщение добавлено!');
            await this.loadMessages();
            await this.loadAppInfo();

        } catch (error) {
            console.error('Ошибка отправки:', error);
            alert('Ошибка: ' + error.message);
        }
    }

    setupEventListeners() {
        document.getElementById('message-form').addEventListener('submit', async (e) => {
            e.preventDefault();

            const author = document.getElementById('author').value;
            const message = document.getElementById('message').value;

            if (!message) {
                alert('Введите сообщение');
                return;
            }

            await this.addMessage(author, message);
            document.getElementById('message').value = '';
        });

        document.getElementById('refresh-info').addEventListener('click', () => {
            this.loadAppInfo();
        });
    }
}

document.addEventListener('DOMContentLoaded', () => {
    new GuestBookApp();
});

python3 -m venv venv
source venv/bin/activate
pip install "python-lsp-server[all]"
pip install ruff-lsp
if [ -e "./requirements/local.txt" ]
then
    pip install -r requirements/local.txt
fi

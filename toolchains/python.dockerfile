FROM zalando/python:3.5.0-4

# install Python "wheel" to upload "binary" wheel packages to PyPI
# (python3 setup.py bdist_wheel)
RUN pip3 install wheel virtualenv flake8

COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]

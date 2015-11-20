FROM zalando/python:3.5.0-3

# install Python "wheel" to upload "binary" wheel packages to PyPI
# (python3 setup.py bdist_wheel)
RUN pip3 install wheel virtualenv

WORKDIR /work
COPY switch-user.sh /switch-user.sh
ENTRYPOINT ["/switch-user.sh"]

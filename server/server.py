#!/usr/bin/env python

import os
import sys
import struct
import tempfile
import threading

import glib
import glib.option
import gobject

import gst

gobject.threads_init()

from SocketServer import ThreadingMixIn, TCPServer, BaseRequestHandler
from BaseHTTPServer import HTTPServer, BaseHTTPRequestHandler

class Recognizer(object):
	DICT_FOLDER = os.path.join(os.path.dirname(__file__), 'dict')
	DICT_NAME = 'grammar'

	def __init__(self):
		self.lock = threading.Lock()

		self.callback = None

		self.pipeline = gst.parse_launch(' ! '.join([
			'filesrc name=source',
			'aiffparse',
			'audioconvert',
			'audioresample',
			'pocketsphinx name=sphinx',
			'fakesink'
		]))

		self.source = self.pipeline.get_by_name('source')
		self.sphinx = self.pipeline.get_by_name('sphinx')

		self.sphinx.connect('partial_result', self.on_sphinx_partial_result)
		self.sphinx.connect('result', self.on_sphinx_result)

		self.sphinx.props.dict = self.get_file_name('.dic')
		self.sphinx.props.fsg = self.get_file_name('.fsg')
		self.sphinx.props.maxhmmpf = 2000
		self.sphinx.props.configured = True

		self.pipeline.auto_clock()

		self.bus = self.pipeline.get_bus()
		self.bus.add_signal_watch()
		self.bus.connect('message', self.on_bus_message)

		result = self.pipeline.set_state(gst.STATE_READY)

		if result == gst.STATE_CHANGE_ASYNC:
			result, state, pending = self.pipeline.get_state()

			if result != gst.STATE_CHANGE_SUCCESS or state != gst.STATE_READY:
				raise Exception("Couldn't start pipeline.")

	@classmethod
	def get_file_name(cls, ext):
		return os.path.join(cls.DICT_FOLDER, cls.DICT_NAME + ext)

	def on_sphinx_partial_result(self, sphinx, text, uttid):
		pass

	def on_sphinx_result(self, sphinx, text, uttid):
		msg = gst.Structure('sphinx_result')
		msg['text'] = text

		self.bus.post(gst.message_new_application(sphinx, msg))

	def on_bus_message(self, bus, msg):
		if msg.type == gst.MESSAGE_APPLICATION:
			self.pipeline.set_state(gst.STATE_READY)
			if self.callback:
				self.callback(msg.structure['text'])
				self.callback = None
		if msg.type == gst.MESSAGE_EOS:
			self.pipeline.set_state(gst.STATE_READY)
			if self.callback:
				self.callback(msg.structure['text'])
				self.callback = None
		elif msg.type == gst.MESSAGE_ERROR:
			err, debug = msg.parse_error()
			self.callback = None
			print "Error: %s" % err, debug

	def recognize(self, filename, callback):
		with self.lock:
			if self.callback is not None:
				return False

			self.callback = callback

			result, state, pending = self.pipeline.get_state()

			if result != gst.STATE_CHANGE_SUCCESS or state != gst.STATE_READY:
				return False

			self.source.props.location = filename

			result = self.pipeline.set_state(gst.STATE_PLAYING)

			return True

class HCIPlayerRequestHandler(BaseHTTPRequestHandler):
	def do_POST(self):
		result = [None]

		stream = tempfile.NamedTemporaryFile(prefix='hciplayer-', suffix='.aiff', delete=True)

		length = int(self.headers['Content-length'])

		stream.write(self.rfile.read(length))

		stream.flush()

		finished = threading.Event()

		def callback(text):
			result[0] = text.lower()
			finished.set()

		self.server.recognizer.recognize(stream.name, callback)

		finished.wait()

		self.send_response(200)
		self.send_header('Content-type', 'text/plain')
		self.end_headers()
		self.wfile.write(result[0])

		print '  --> RESULT: "%s"' % result[0]

class HCIPlayerServer(HTTPServer, object):
	allow_reuse_address = True

	def __init__(self, *args, **kwargs):
		super(HCIPlayerServer, self).__init__(*args, **kwargs)

		self.recognizer = Recognizer()

def main():
	server = HCIPlayerServer(('0.0.0.0', 9090), HCIPlayerRequestHandler)

	thread = threading.Thread(target=server.serve_forever)
	thread.daemon = True
	thread.start()

	glib.MainLoop().run()

if __name__ == '__main__':
	main()
